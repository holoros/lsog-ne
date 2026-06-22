const fs = require("fs");
const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell, ImageRun,
        Header, Footer, AlignmentType, BorderStyle, WidthType, ShadingType,
        HeadingLevel, TableOfContents, PageNumber, PageBreak } = require("docx");

const MD  = "/sessions/vibrant-lucid-faraday/mnt/outputs/mfpc_report.md";
const FIG = "/sessions/vibrant-lucid-faraday/mnt/outputs";
const src = fs.readFileSync(MD, "utf8").split("\n");

// Unicode sub/superscript + symbol normalizer applied to all text
function S(t){ return String(t)
  .replace(/CO2e/g,"CO₂e").replace(/CO2/g,"CO₂")
  .replace(/m\^3/g,"m³").replace(/m3\b/g,"m³")
  .replace(/ft\^2/g,"ft²").replace(/km\^2/g,"km²")
  .replace(/R\^2/g,"R²").replace(/ha\^-1/g,"ha⁻¹")
  .replace(/>=/g,"≥").replace(/<=/g,"≤")
  .replace(/\+\/-/g,"±").replace(/\+-/g,"±"); }
const BLUE = "1F4E5F", LT = "DCE6EA";
const border = { style: BorderStyle.SINGLE, size: 1, color: "AAB7BD" };
const borders = { top: border, bottom: border, left: border, right: border };
function tc(text, w, head){ return new TableCell({ borders, width:{size:w,type:WidthType.DXA},
  shading: head?{fill:LT,type:ShadingType.CLEAR}:undefined,
  margins:{top:60,bottom:60,left:110,right:110},
  children:[new Paragraph({children:[new TextRun({text:S(text),bold:!!head,size:19})]})] }); }
function table(rows, widths){ const tot=widths.reduce((a,b)=>a+b,0);
  return new Table({ width:{size:tot,type:WidthType.DXA}, columnWidths:widths,
    rows: rows.map((r,ri)=>new TableRow({children:r.map((c,ci)=>tc(c,widths[ci],ri===0))})) }); }
function P(text){ return new Paragraph({ spacing:{after:140,line:300},
  children:[new TextRun({text:S(text), size:22})] }); }

const children = [];

// ---- Title block ----
children.push(new Paragraph({ spacing:{before:1200,after:120}, alignment:AlignmentType.CENTER,
  children:[new TextRun({text:"Late-Successional and Old-Growth Forest Across Northern New England", bold:true, size:40, color:BLUE})] }));
children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{after:300},
  children:[new TextRun({text:"What the Inventory Shows, and the Limits of LiDAR-Based Mapping", italics:true, size:26})] }));
children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{after:80},
  children:[new TextRun({text:"A Technical Report for the Maine Forest Products Council", bold:true, size:24})] }));
children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{after:60},
  children:[new TextRun({text:"Aaron R. Weiskittel and colleagues", size:22})] }));
children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{after:40},
  children:[new TextRun({text:"Center for Research on Sustainable Forests, University of Maine", size:20, italics:true})] }));
children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{after:600},
  children:[new TextRun({text:"June 2026", size:20})] }));
children.push(new Paragraph({ children:[new PageBreak()] }));

// ---- TOC (static) ----
children.push(new Paragraph({ heading:HeadingLevel.HEADING_1, children:[new TextRun({text:"Contents"})] }));
for (const t of ["Executive summary","1.  Background","2.  Primary limitations of the LiDAR analysis and the RAP protocol",
  "3.  Our primary findings: a regional, design-based account","4.  Robustness: stress testing the conclusions",
  "5.  Implications for Maine and the regional forest economy","6.  Recommendations","7.  Methods and data availability"]){
  children.push(new Paragraph({ spacing:{after:60}, children:[new TextRun({text:t, size:22})] }));
}
children.push(new Paragraph({ children:[new PageBreak()] }));

// ---- parse body ----
const KEYFIND_AFTER = "On the mapping itself";   // inject key-findings table after exec summary paragraph that starts here? we inject before section 1
let injectedKeyTable=false, injectedStress=false, injectedFig=false;
for (let i=0;i<src.length;i++){
  let line = src[i].trim();
  if (line==="" || line==="---") continue;
  // stop title block lines already emitted
  if (line.startsWith("# ")) continue; // main title (handled)
  if (line.startsWith("## What the Inventory")) continue;
  if (line.startsWith("### A Technical Report")) continue;
  if (line.startsWith("Prepared by Aaron")) continue;

  if (line.startsWith("### ")){
    children.push(new Paragraph({ heading:HeadingLevel.HEADING_2, spacing:{before:160,after:80},
      children:[new TextRun({text:S(line.replace(/^###\s*/,""))})] }));
  } else if (line.startsWith("## ")){
    const h = S(line.replace(/^##\s*/,""));
    // inject key-findings table right before Section 1 Background
    if (h.startsWith("1. Background") && !injectedKeyTable){
      children.push(new Paragraph({ heading:HeadingLevel.HEADING_2, spacing:{before:120,after:80}, children:[new TextRun({text:"Summary of primary findings"})] }));
      children.push(table([
        ["Question","Our finding (design-based, regional)"],
        ["How much LSOG exists?","A range with sampling intervals, not a point: 3.9% [3.3-4.6] of Maine forestland at stand age ≥120 yr; 14.1% [12.9-15.3] under the integrated structural proxy."],
        ["How sensitive to definition?","The same forest is ~3% LSOG (all four axes) to over 90% (one axis). The headline number is a definitional choice."],
        ["Regional ranking","Maine carries the lowest integrated share; this is the expected signature of its production role in a regional triad, not a per-state deficit."],
        ["Is it disappearing?","Net older-forest stock is stable to rising, 2003-2024. The cited loss rate is a gross harvest flux, not a declining net stock."],
        ["Do the maps agree?","Independent credible maps disagree 1.6 to 2.6 fold in amount and agree on only a few percent of the specific ground."],
      ], [2600,6760]));
      children.push(new Paragraph({ spacing:{after:160}, children:[new TextRun({text:"",size:8})] }));
      injectedKeyTable=true;
    }
    children.push(new Paragraph({ heading:HeadingLevel.HEADING_1, spacing:{before:240,after:120},
      children:[new TextRun({text:h})] }));
  } else {
    children.push(P(line));
    // inject ensemble + uncertainty figure after the §3.5 probability-surface paragraph
    if (line.startsWith("Rather than a single binary map")){
      children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{before:120,after:60},
        children:[new ImageRun({ type:"png", data:fs.readFileSync(`${FIG}/msFig_ensemble_uncertainty.png`),
          transformation:{width:640,height:504}, altText:{title:"ensemble uncertainty",description:"ensemble probability and uncertainty",name:"ens_unc"} })] }));
      children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{after:160},
        children:[new TextRun({text:"Figure 2. (a) Multi-model ensemble probability of LSOG across Maine, averaging five statistical learners. (b) Across-model uncertainty, the standard deviation among the five models per pixel (mean 0.18 on a 0-1 scale). Darker areas are where credible models disagree most about whether the forest is LSOG.", italics:true, size:18})] }));
    }
    // inject 3-map figure after the cross-map paragraph (2.4)
    if (!injectedFig && line.startsWith("When three independent remote-sensing")){
      children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{before:120,after:60},
        children:[new ImageRun({ type:"png", data:fs.readFileSync(`${FIG}/msComment_ensemble.png`),
          transformation:{width:620,height:362}, altText:{title:"ensemble",description:"three-map ensemble",name:"ensemble"} })] }));
      children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{after:160},
        children:[new TextRun({text:"Figure 1. Three independent remote-sensing maps of LSOG over Maine: Hagan airborne LiDAR (21.9%), Potapov/GEDI spaceborne canopy height (14.0%), and the ORNL national old-growth product (36.1%), with the number of maps agreeing per cell. Only ~3% of flagged acres are agreed by all three.", italics:true, size:18})] }));
      injectedFig=true;
    }
    // inject stress-test table inside Robustness section
    if (!injectedStress && line.startsWith("We stress tested")){
      children.push(new Paragraph({ spacing:{before:120,after:60}, children:[new TextRun({text:"Stress test: does “Maine lowest” survive the analytical choices? (plot-level prevalence used for ordering)", bold:true, size:20})] }));
      children.push(table([
        ["Perturbation","Maine share","Maine lowest of 4?"],
        ["Any-LSOG cutoff, looser (score ≥3)","40.9%","Yes"],
        ["Any-LSOG cutoff, base (score ≥4)","24.8%","Yes"],
        ["Any-LSOG cutoff, tighter (score ≥5)","12.9%","Yes"],
        ["True-LSOG cutoff (score ≥7)","1.9%","Yes"],
        ["True-LSOG cutoff (score ≥8)","0.4%","Yes"],
        ["True-LSOG cutoff, extreme (score ≥9)","0.1%","No (all states ~0.1%, noise)"],
        ["Canopy dimension removed entirely","20.3%","Yes"],
        ["FIA panel 2014-2018","23.9%","Yes"],
        ["FIA panel 2019-2023","25.8%","Yes"],
      ], [4760,2300,2300]));
      children.push(new Paragraph({ spacing:{after:160}, children:[new TextRun({text:"Maine is the lowest-share state in 8 of 9 perturbations; the lone exception is an extreme cutoff where every state collapses to about one-tenth of one percent.", italics:true, size:18})] }));
      injectedStress=true;
    }
  }
}

const doc = new Document({
  styles: {
    default: { document: { run: { font:"Arial", size:22 } } },
    paragraphStyles: [
      { id:"Heading1", name:"Heading 1", basedOn:"Normal", next:"Normal", quickFormat:true,
        run:{ size:28, bold:true, font:"Arial", color:BLUE },
        paragraph:{ spacing:{before:240,after:120}, outlineLevel:0 } },
      { id:"Heading2", name:"Heading 2", basedOn:"Normal", next:"Normal", quickFormat:true,
        run:{ size:23, bold:true, font:"Arial", color:"333333" },
        paragraph:{ spacing:{before:160,after:80}, outlineLevel:1 } },
    ]
  },
  sections: [{
    properties: { page: { size:{width:12240,height:15840}, margin:{top:1440,right:1440,bottom:1440,left:1440} } },
    headers: { default: new Header({ children:[new Paragraph({ alignment:AlignmentType.RIGHT,
      border:{bottom:{style:BorderStyle.SINGLE,size:4,color:BLUE,space:2}},
      children:[new TextRun({text:"LSOG in Northern New England — Technical Report for the Maine Forest Products Council", size:14, color:"777777"})] })] }) },
    footers: { default: new Footer({ children:[new Paragraph({ alignment:AlignmentType.CENTER,
      children:[new TextRun({text:"Page ",size:16}), new TextRun({children:[PageNumber.CURRENT],size:16})] })] }) },
    children,
  }],
});
Packer.toBuffer(doc).then((b)=>{ fs.writeFileSync("/sessions/vibrant-lucid-faraday/mnt/outputs/MFPC_LSOG_Technical_Report.docx", b);
  console.log("wrote", b.length, "bytes"); });
