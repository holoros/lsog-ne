const fs = require("fs");
const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
        ImageRun, AlignmentType, BorderStyle, WidthType, ShadingType,
        PageBreak, LineNumberRestartFormat } = require("docx");

const MD = "/sessions/vibrant-lucid-faraday/mnt/outputs/manuscript_final.md";
const FIG = "/sessions/vibrant-lucid-faraday/mnt/outputs/ms_figs";
const src = fs.readFileSync(MD, "utf8").split("\n");

const border = { style: BorderStyle.SINGLE, size: 1, color: "999999" };
const borders = { top: border, bottom: border, left: border, right: border };
const CONTENT = 9360;

// Unicode sub/superscript + symbol normalizer
function S(t){ t = String(t)
  .replace(/CO2e/g,"CO₂e").replace(/CO2/g,"CO₂")
  .replace(/m\^3/g,"m³").replace(/ft\^2/g,"ft²").replace(/km\^2/g,"km²")
  .replace(/R\^2/g,"R²").replace(/ha\^-1/g,"ha⁻¹")
  .replace(/>=/g,"≥").replace(/<=/g,"≤").replace(/\+\/-/g,"±"); t = t.split(/(\s+)/).map(function(w){return /https?:\/\/|doi\.org/.test(w)?w:w.replace(/(\d)-(\d)/g,"$1\u2013$2");}).join(""); return t; }

function runs(text) {
  text = S(text);
  // bold **..**, italic *..*
  const out = []; let i = 0;
  const re = /(\*\*[^*]+\*\*|\*[^*]+\*)/g; let last = 0; let m;
  while ((m = re.exec(text))) {
    if (m.index > last) out.push(new TextRun({ text: text.slice(last, m.index), size: 24 }));
    const t = m[0];
    if (t.startsWith("**")) out.push(new TextRun({ text: t.slice(2, -2), bold: true, size: 24 }));
    else out.push(new TextRun({ text: t.slice(1, -1), italics: true, size: 24 }));
    last = m.index + t.length;
  }
  if (last < text.length) out.push(new TextRun({ text: text.slice(last), size: 24 }));
  if (out.length === 0) out.push(new TextRun({ text: "", size: 24 }));
  return out;
}
function para(text, opts = {}) {
  return new Paragraph({ spacing: { line: opts.line || 480, before: opts.before || 0, after: opts.after || 0 },
    children: runs(text) });
}
function heading(text, lvl) {
  const size = lvl === 1 ? 26 : 24;
  return new Paragraph({ spacing: { line: 480, before: 200, after: 60 },
    children: [new TextRun({ text, bold: true, size })] });
}
function tcell(text, w, head) {
  return new TableCell({ borders, width: { size: w, type: WidthType.DXA },
    shading: head ? { fill: "D9E2EC", type: ShadingType.CLEAR } : undefined,
    margins: { top: 40, bottom: 40, left: 90, right: 90 },
    children: [new Paragraph({ spacing: { line: 240 }, children: [new TextRun({ text: S(text), bold: !!head, size: 19 })] })] });
}
function mdtable(rows) {
  const ncol = rows[0].length;
  const w = Math.floor(CONTENT / ncol);
  const widths = Array(ncol).fill(w); widths[0] = CONTENT - w * (ncol - 1);
  return new Table({ width: { size: CONTENT, type: WidthType.DXA }, columnWidths: widths,
    rows: rows.map((r, ri) => new TableRow({ children: r.map((c, ci) => tcell(c, widths[ci], ri === 0)) })) });
}

const children = [];
let i = 0;
while (i < src.length) {
  let line = src[i];
  if (line.trim() === "" || line.trim() === "---") { i++; continue; }
  if (line.startsWith("# ")) { // title
    children.push(new Paragraph({ spacing: { line: 320, after: 120 },
      children: [new TextRun({ text: line.slice(2), bold: true, size: 30 })] })); i++; continue;
  }
  if (line.startsWith("## ")) { children.push(heading(line.slice(3), 1)); i++; continue; }
  if (line.startsWith("### ")) { children.push(heading(line.slice(4), 2)); i++; continue; }
  if (line.startsWith("|")) { // table block
    const block = [];
    while (i < src.length && src[i].startsWith("|")) { block.push(src[i]); i++; }
    const rows = block
      .filter((r) => !/^\|[\s:|-]+\|?$/.test(r.replace(/\s/g, "").replace(/\|/g, "|")) || !/^[-:\s|]+$/.test(r.replace(/\|/g, "")))
      .filter((r) => !/^\s*\|?[\s:-]*\|[\s:|-]*$/.test(r) || r.replace(/[|\s:-]/g, "") !== "")
      .map((r) => r.split("|").slice(1, -1).map((c) => c.trim()));
    // remove separator rows (all dashes)
    const clean = rows.filter((r) => !r.every((c) => /^:?-+:?$/.test(c) || c === ""));
    children.push(mdtable(clean));
    children.push(new Paragraph({ spacing: { line: 120 }, children: [new TextRun("")] }));
    continue;
  }
  // bold caption like **Table 1.** ...
  children.push(para(line));
  i++;
}

// Append figures at end on separate pages
const figDims = {
  "Fig_datamap.png": [2100, 2280], "msFig2_4state_fixed.png": [1504, 1578], "msFig3.png": [3000, 1750],
  "msFig4.png": [1600, 950], "msFig5.png": [2520, 1680], "msFig6_prob_surface.png": [1500, 1900], "msFig_refined_map.png": [2700, 1850],
};
const figW = { "Fig_datamap.png": 5.1, "msFig2_4state_fixed.png": 5.6, "msFig3.png": 6.4, "msFig4.png": 6.2, "msFig5.png": 6.2, "msFig6_prob_surface.png": 4.3, "msFig_refined_map.png": 6.6 };
let fnum = 1;
for (const f of ["Fig_datamap.png","msFig2_4state_fixed.png","msFig3.png","msFig4.png","msFig5.png","msFig6_prob_surface.png","msFig_refined_map.png"]) {
  children.push(new Paragraph({ children: [new PageBreak()] }));
  children.push(new Paragraph({ spacing: { after: 60 }, children: [new TextRun({ text: "Figure " + fnum, bold: true, size: 22 })] }));
  const wIn = figW[f] * 96, h = wIn * figDims[f][1] / figDims[f][0];
  children.push(new Paragraph({ alignment: AlignmentType.CENTER,
    children: [new ImageRun({ type: "png", data: fs.readFileSync(`${FIG}/${f}`),
      transformation: { width: Math.round(wIn), height: Math.round(h) },
      altText: { title: f, description: f, name: f } })] }));
  fnum++;
}

const doc = new Document({
  styles: { default: { document: { run: { font: "Times New Roman", size: 24 } } } },
  sections: [{
    properties: { page: { size: { width: 12240, height: 15840 },
      margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 },
      lineNumbers: { countBy: 1, restart: LineNumberRestartFormat.CONTINUOUS, distance: 360 } } },
    children,
  }],
});
Packer.toBuffer(doc).then((b) => {
  fs.writeFileSync("/sessions/vibrant-lucid-faraday/mnt/outputs/Northeast_LSOG_Manuscript_V2.docx", b);
  console.log("wrote", b.length, "bytes");
});
