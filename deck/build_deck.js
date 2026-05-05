// Northeast LSOG project slide deck
const pptxgen = require("pptxgenjs");
const path = require("path");

const FIG = "/sessions/modest-sweet-archimedes/mnt/ME/LSOG_cardinal_setup";

let pres = new pptxgen();
pres.layout = "LAYOUT_WIDE";   // 13.3 x 7.5
pres.author = "A. Weiskittel";
pres.title = "Northeast LSOG: A Multi-Source FIA-Proxy Analysis";

// Forest & Moss palette
const C = {
  forest:  "2C5F2D",
  moss:    "97BC62",
  cream:   "F5F5F5",
  ink:     "1A2E1B",
  muted:   "5B6F5E",
  accent:  "B85042",
  white:   "FFFFFF",
  light_g: "E8EDD9"
};

// ---- Slide 1: Title ----
{
  let s = pres.addSlide();
  s.background = { color: C.forest };

  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 6.0, w: 13.3, h: 0.18, fill: { color: C.moss }, line: { color: C.moss }
  });

  s.addText("NORTHEAST LSOG", {
    x: 0.7, y: 1.6, w: 12, h: 0.6,
    fontSize: 18, fontFace: "Calibri", color: C.moss, bold: true,
    charSpacing: 8, margin: 0
  });

  s.addText("A Multi-Source FIA-Proxy\nClassification of Late-Successional and Old-Growth Forest", {
    x: 0.7, y: 2.4, w: 12, h: 2.0,
    fontSize: 40, fontFace: "Georgia", color: C.white, bold: true, margin: 0,
    paraSpaceAfter: 6
  });

  s.addText("Maine, New Hampshire, Vermont, New York   |   Cardinal HPC   |   April 2026", {
    x: 0.7, y: 4.7, w: 12, h: 0.4,
    fontSize: 14, fontFace: "Calibri", color: C.cream, italic: true, margin: 0
  });

  s.addText("A. Weiskittel  |  Center for Research on Sustainable Forests, University of Maine", {
    x: 0.7, y: 5.2, w: 12, h: 0.4,
    fontSize: 12, fontFace: "Calibri", color: C.cream, margin: 0
  });

  s.addText("github.com/holoros/lsog-ne", {
    x: 0.7, y: 6.4, w: 12, h: 0.4,
    fontSize: 11, fontFace: "Consolas", color: C.moss, margin: 0
  });

  s.addNotes("Open with: this work was done on Cardinal HPC over the past several weeks. The repository is public. Goal of the talk is to share what the multi-source FIA-proxy approach can and cannot tell us about Northeast LSOG distribution.");
}

// helper
function addContentTitle(s, title, subtitle) {
  s.background = { color: C.cream };
  s.addText(title, {
    x: 0.5, y: 0.35, w: 12.3, h: 0.65,
    fontSize: 30, fontFace: "Georgia", color: C.forest, bold: true, margin: 0
  });
  if (subtitle) {
    s.addText(subtitle, {
      x: 0.5, y: 1.0, w: 12.3, h: 0.4,
      fontSize: 13, fontFace: "Calibri", color: C.muted, italic: true, margin: 0
    });
  }
}

function addSectionDivider(label, kicker) {
  let s = pres.addSlide();
  s.background = { color: C.forest };
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 3.4, w: 13.3, h: 0.06, fill: { color: C.moss }, line: { color: C.moss }
  });
  s.addText(kicker, {
    x: 0.7, y: 2.7, w: 12, h: 0.5,
    fontSize: 16, fontFace: "Calibri", color: C.moss, bold: true,
    charSpacing: 8, margin: 0
  });
  s.addText(label, {
    x: 0.7, y: 3.6, w: 12, h: 1.6,
    fontSize: 60, fontFace: "Georgia", color: C.cream, bold: true, margin: 0
  });
  return s;
}

// ---- Slide 2: TL;DR ----
{
  let s = pres.addSlide();
  addContentTitle(s, "TL;DR — Five Findings",
    "What the regional analysis tells us before we get into the methods");

  const tldr = [
    ["1", "Maine has the lowest LSOG share in the Northeast",
        "v5.1 design-based estimate: ME 14.1%, NH 31.2%, VT 28.8%, NY 27.2%"],
    ["2", "Northeast forests are aging — except in Maine",
        "NH +11.1, VT +9.1, NY +8.9 percentage points per decade (1999 to 2023). ME +1.6 pp, borderline significant."],
    ["3", "Public lands carry 1.5 to 3x the LSOG concentration of private lands",
        "ME federal 36% vs private 14%. NY State+Local has more LS+OG (583 K ac) than ME has across all owners."],
    ["4", "OG-class plots store 2.6 to 3.6x the live carbon of Not-LSOG plots",
        "ME OG = 139 Mg C / ha. Direct climate-mandate relevance for LD 1529."],
    ["5", "FIA-proxy and LiDAR LSOG products measure different things",
        "Pingree validation (Phase 9, n=125): aggregate v4 share matches Hagan (16.8 vs 18.8%) but plot-by-plot kappa is random. Skid trails / harvest legacy are visible to LiDAR canopy metrics; tree-level changes are visible to FIA."]
  ];

  for (let i = 0; i < tldr.length; i++) {
    const y = 1.55 + i * 1.07;
    s.addShape(pres.shapes.OVAL, {
      x: 0.5, y, w: 0.7, h: 0.7, fill: { color: C.forest }, line: { color: C.forest }
    });
    s.addText(tldr[i][0], {
      x: 0.5, y, w: 0.7, h: 0.7, fontSize: 24, fontFace: "Georgia",
      color: C.cream, bold: true, align: "center", valign: "middle", margin: 0
    });
    s.addText(tldr[i][1], {
      x: 1.45, y: y - 0.05, w: 11.5, h: 0.42,
      fontSize: 16, fontFace: "Georgia", color: C.forest, bold: true, margin: 0
    });
    s.addText(tldr[i][2], {
      x: 1.45, y: y + 0.36, w: 11.5, h: 0.7,
      fontSize: 12, fontFace: "Calibri", color: C.ink, margin: 0
    });
  }

  s.addNotes("Five-point summary so the audience knows the destination before we walk through methods. Encourage the room to interrupt at any point. Finding 5 is the honest caveat. The Phase 9 SILC / Hagan validation is the most recent evidence for it: aggregate share matches but plot-by-plot agreement is random because skid trails and selective harvest produce different signatures in LiDAR canopy metrics versus FIA tree-level data.");
}

// ---- Section divider: Methods ----
addSectionDivider("Methods", "PART 01").addNotes("Brief transition. We are about to spend two slides on the v5.1 classifier and how it scores plots.");

// ---- Slide 2 (now after divider): Why this matters ----
{
  let s = pres.addSlide();
  addContentTitle(s, "Why This Matters",
    "Old-growth forest is rare, valuable, and politically salient — but hard to measure");

  s.addShape(pres.shapes.RECTANGLE, {
    x: 0.5, y: 1.7, w: 6.0, h: 5.3, fill: { color: C.white }, line: { color: C.light_g, width: 1 }
  });
  s.addText("THE CONTEXT", {
    x: 0.7, y: 1.9, w: 5.6, h: 0.4, fontSize: 12, fontFace: "Calibri",
    color: C.moss, bold: true, charSpacing: 4, margin: 0
  });
  s.addText([
    { text: "LD 1529 (Maine, 2025)", options: { bullet: true, breakLine: true, bold: true, color: C.forest } },
    { text: "  Directs DACF to produce a comprehensive LSOG conservation report by Nov 2026, incorporating ecological, carbon, and economic considerations.", options: { breakLine: true, color: C.ink, fontSize: 12 } },
    { text: "Hagan et al. 2024 LiDAR mapping", options: { bullet: true, breakLine: true, bold: true, color: C.forest } },
    { text: "  Identified ~165,000 ha of unmapped old forest in Maine's unorganized territories.", options: { breakLine: true, color: C.ink, fontSize: 12 } },
    { text: "Thompson et al. 2026", options: { bullet: true, breakLine: true, bold: true, color: C.forest } },
    { text: "  Pathways for protecting Maine's remaining old-growth on private commercial timberlands.", options: { breakLine: true, color: C.ink, fontSize: 12 } },
    { text: "Pelz et al. 2023 (FEM 549)", options: { bullet: true, breakLine: true, bold: true, color: C.forest } },
    { text: "  Official USFS old-growth methodology applied to FIA on National Forest System lands.", options: { color: C.ink, fontSize: 12 } }
  ], { x: 0.8, y: 2.3, w: 5.5, h: 4.6, fontSize: 13, fontFace: "Calibri", paraSpaceAfter: 4, margin: 0 });

  s.addShape(pres.shapes.RECTANGLE, {
    x: 6.8, y: 1.7, w: 6.0, h: 5.3, fill: { color: C.forest }, line: { color: C.forest }
  });
  s.addShape(pres.shapes.RECTANGLE, {
    x: 6.8, y: 1.7, w: 0.12, h: 5.3, fill: { color: C.accent }, line: { color: C.accent }
  });
  s.addText("PROJECT GOALS", {
    x: 7.05, y: 1.9, w: 5.6, h: 0.4, fontSize: 12, fontFace: "Calibri",
    color: C.moss, bold: true, charSpacing: 4, margin: 0
  });
  s.addText([
    { text: "1.  Build a defensible FIA proxy", options: { breakLine: true, bold: true, color: C.white, fontSize: 15 } },
    { text: "calibrated against Hagan, ORNL, and Pelz benchmarks.", options: { breakLine: true, color: C.cream, fontSize: 12 } },
    { text: " ", options: { breakLine: true } },
    { text: "2.  Extend to NH, VT, NY", options: { breakLine: true, bold: true, color: C.white, fontSize: 15 } },
    { text: "for regional comparison across the Northeast.", options: { breakLine: true, color: C.cream, fontSize: 12 } },
    { text: " ", options: { breakLine: true } },
    { text: "3.  Quantify carbon and ownership", options: { breakLine: true, bold: true, color: C.white, fontSize: 15 } },
    { text: "for direct LD 1529 policy use.", options: { breakLine: true, color: C.cream, fontSize: 12 } },
    { text: " ", options: { breakLine: true } },
    { text: "4.  Produce wall-to-wall maps", options: { breakLine: true, bold: true, color: C.white, fontSize: 15 } },
    { text: "via TreeMap imputation of FIA plots.", options: { color: C.cream, fontSize: 12 } }
  ], { x: 7.05, y: 2.3, w: 5.6, h: 4.7, fontFace: "Calibri", paraSpaceAfter: 0, margin: 0 });

  s.addNotes("Set up the policy context. LD 1529 is the immediate driver; Hagan and Thompson are the dominant Maine literature. Pelz is the USFS-official reference we benchmark against. Mention that Hagan raster is still pending and is the most important remaining external dependency.");
}

// ---- Slide 3: v5.1 classifier ----
{
  let s = pres.addSlide();
  addContentTitle(s, "v5.1 Classifier: Six Dimensions, /12 Score",
    "Operational at github.com/holoros/lsog-ne (R/fia_lsog_analysis_v5.r)");

  const dims = [
    ["1", "Large-tree BA", "BA in trees DBH ≥ 20 in", "1pt: ≥ 40 ft²/ac\n2pt: ≥ 80 ft²/ac"],
    ["2", "Stand maturity", "STDAGE (or max DBH fallback)", "1pt: ≥ 80 yr (or DBH ≥ 24 in)\n2pt: ≥ 120 yr"],
    ["3", "Structure", "TPA-weighted SD of DBH", "1pt: ≥ 5 in\n2pt: ≥ 8 in"],
    ["4", "Total stocking", "Total live BA", "1pt: ≥ 100 ft²/ac\n2pt: ≥ 150 ft²/ac"],
    ["5", "Deadwood", "Snag TPA, data-driven", "1pt: ≥ 75th percentile\n2pt: ≥ 90th"],
    ["6", "Canopy height", "Potapov 2021 GEDI RH95", "1pt: ≥ 18 m\n2pt: ≥ 25 m"]
  ];

  for (let i = 0; i < 6; i++) {
    const col = i % 2, row = Math.floor(i / 2);
    const x = 0.5 + col * 6.4;
    const y = 1.6 + row * 1.7;

    s.addShape(pres.shapes.RECTANGLE, {
      x, y, w: 6.0, h: 1.55, fill: { color: C.white },
      line: { color: C.light_g, width: 1 }
    });
    s.addShape(pres.shapes.RECTANGLE, {
      x, y, w: 0.12, h: 1.55, fill: { color: C.forest }, line: { color: C.forest }
    });
    s.addText(dims[i][0], {
      x: x + 0.25, y: y + 0.15, w: 0.5, h: 0.5,
      fontSize: 28, fontFace: "Georgia", color: C.forest, bold: true, margin: 0
    });
    s.addText(dims[i][1], {
      x: x + 0.85, y: y + 0.18, w: 3.0, h: 0.4,
      fontSize: 16, fontFace: "Georgia", color: C.ink, bold: true, margin: 0
    });
    s.addText(dims[i][2], {
      x: x + 0.85, y: y + 0.6, w: 3.0, h: 0.5,
      fontSize: 11, fontFace: "Calibri", color: C.muted, italic: true, margin: 0
    });
    s.addText(dims[i][3], {
      x: x + 4.0, y: y + 0.18, w: 1.95, h: 1.2,
      fontSize: 11, fontFace: "Calibri", color: C.ink, margin: 0
    });
  }

  s.addShape(pres.shapes.RECTANGLE, {
    x: 0.5, y: 6.85, w: 12.4, h: 0.5, fill: { color: C.forest }, line: { color: C.forest }
  });
  s.addText("CLASS THRESHOLDS:    Transitioning LS  ≥ 4    |    LS  ≥ 6    |    OG  ≥ 8    (out of 12)",
    { x: 0.5, y: 6.85, w: 12.4, h: 0.5, fontSize: 14, fontFace: "Calibri",
      color: C.cream, bold: true, align: "center", valign: "middle", margin: 0, charSpacing: 2 });

  s.addNotes("v5.1 is the operational classifier. Six dimensions, two points possible per dimension, /12 total. Dimensions 1 to 5 come from FIA tree and condition tables. Dimension 6 (Potapov RH95) is derived from GEDI-fused 30 m canopy height. Thresholds were calibrated by grid search against ORNL 2498 and Hagan 2024 references.");
}

// ---- Section divider: Results ----
addSectionDivider("Results", "PART 02").addNotes("Transition into the regional findings: state shares, time series, ownership, and carbon.");

// ---- Slide 4: Headline regional results ----
{
  let s = pres.addSlide();
  addContentTitle(s, "Headline Regional Results (FIA panel 2019-2023)",
    "v5.1 plot-based bootstrap estimates with 95% confidence intervals");

  s.addImage({
    path: path.join(FIG, "figures/fig1_state_all_lsog_pct.png"),
    x: 0.5, y: 1.6, w: 7.5, h: 4.5
  });

  s.addShape(pres.shapes.RECTANGLE, {
    x: 8.4, y: 1.6, w: 4.5, h: 5.6, fill: { color: C.white }, line: { color: C.light_g, width: 1 }
  });
  s.addShape(pres.shapes.RECTANGLE, {
    x: 8.4, y: 1.6, w: 0.12, h: 5.6, fill: { color: C.forest }, line: { color: C.forest }
  });

  s.addText("STATE-LEVEL SHARES", {
    x: 8.7, y: 1.75, w: 4.0, h: 0.4, fontSize: 12, fontFace: "Calibri",
    color: C.moss, bold: true, charSpacing: 4, margin: 0
  });

  const stateData = [
    ["Maine",         "14.1%",  "12.9 - 15.3"],
    ["New Hampshire", "31.2%",  "28.0 - 34.3"],
    ["Vermont",       "28.8%",  "25.4 - 32.3"],
    ["New York",      "27.2%",  "25.2 - 29.0"]
  ];
  for (let i = 0; i < 4; i++) {
    const y = 2.3 + i * 1.05;
    s.addText(stateData[i][0], {
      x: 8.7, y, w: 4.0, h: 0.4, fontSize: 14, fontFace: "Calibri",
      color: C.muted, bold: true, margin: 0
    });
    s.addText(stateData[i][1], {
      x: 8.7, y: y + 0.35, w: 2.5, h: 0.55,
      fontSize: 32, fontFace: "Georgia", color: C.forest, bold: true, margin: 0
    });
    s.addText("any-LSOG (95% CI " + stateData[i][2] + ")", {
      x: 8.7, y: y + 0.85, w: 4.0, h: 0.18, fontSize: 9, fontFace: "Calibri",
      color: C.muted, italic: true, margin: 0
    });
  }

  s.addText("Maine = lowest LSOG share in NE\ndespite highest absolute forest area",
    { x: 8.7, y: 6.75, w: 4.0, h: 0.45, fontSize: 11, fontFace: "Calibri",
      color: C.accent, italic: true, margin: 0 });

  s.addNotes("Headline finding. Bootstrap CIs are non-overlapping between Maine and the other three states. Pause for the visual: Maine sits visibly lower than NH/VT/NY despite carrying far more total forest acreage. Discuss why: heavier industrial harvest history.");
}

// ---- Slide 5: Time series ----
{
  let s = pres.addSlide();
  addContentTitle(s, "Forests Are Aging: 20-year LSOG Trend (1999-2023)",
    "v4 baseline (no GEDI), comparable across all 5 FIA panels");

  s.addImage({
    path: path.join(FIG, "figures/fig3_v4_timeseries_1999_2023.png"),
    x: 0.5, y: 1.5, w: 8.5, h: 4.5
  });

  s.addShape(pres.shapes.RECTANGLE, {
    x: 9.4, y: 1.5, w: 3.5, h: 5.7, fill: { color: C.white }, line: { color: C.light_g, width: 1 }
  });
  s.addShape(pres.shapes.RECTANGLE, {
    x: 9.4, y: 1.5, w: 0.12, h: 5.7, fill: { color: C.forest }, line: { color: C.forest }
  });
  s.addText("TREND TEST", {
    x: 9.65, y: 1.65, w: 3.2, h: 0.35, fontSize: 11, fontFace: "Calibri",
    color: C.moss, bold: true, charSpacing: 4, margin: 0
  });
  s.addText("All-LSOG % per decade", {
    x: 9.65, y: 2.0, w: 3.2, h: 0.3, fontSize: 11, fontFace: "Calibri",
    color: C.muted, italic: true, margin: 0
  });

  const trends = [
    ["NH", "+11.1", "p < 0.001", true],
    ["VT", "+9.1",  "p = 0.024", true],
    ["NY", "+8.9",  "p = 0.002", true],
    ["ME", "+1.6",  "p = 0.057", false]
  ];
  for (let i = 0; i < 4; i++) {
    const y = 2.5 + i * 1.05;
    const [st, slope, p, sig] = trends[i];
    s.addText(st, {
      x: 9.65, y, w: 0.6, h: 0.5, fontSize: 22, fontFace: "Georgia",
      color: sig ? C.forest : C.muted, bold: true, margin: 0
    });
    s.addText(slope + " pp", {
      x: 10.4, y, w: 1.5, h: 0.5, fontSize: 22, fontFace: "Georgia",
      color: sig ? C.forest : C.muted, bold: true, margin: 0
    });
    s.addText(p, {
      x: 9.65, y: y + 0.55, w: 3.0, h: 0.3, fontSize: 11, fontFace: "Calibri",
      color: sig ? C.accent : C.muted, italic: true, margin: 0
    });
  }

  s.addText("Maine slope = borderline\n(intensive harvest dampens aging signal)",
    { x: 9.65, y: 6.7, w: 3.2, h: 0.5, fontSize: 10, fontFace: "Calibri",
      color: C.accent, italic: true, margin: 0 });

  s.addNotes("Five FIA panels span 1999 to 2023. v4 score (no Potapov) is comparable across all years because GEDI was not yet available before 2019. NH, VT, NY trends are highly significant. Maine's near-zero slope is consistent with the active-harvest hypothesis.");
}

// ---- Slide 6: Ownership ----
{
  let s = pres.addSlide();
  addContentTitle(s, "Ownership: Public Lands Have 1.5-3× Higher LSOG Concentration",
    "Design-based EXPNS-weighted estimation, latest panel");

  s.addImage({
    path: path.join(FIG, "figures/design_based/fig8_ownership_lsog_pct.png"),
    x: 0.5, y: 1.5, w: 7.5, h: 4.0
  });

  s.addImage({
    path: path.join(FIG, "figures/design_based/fig9_ownership_lsog_acres.png"),
    x: 0.5, y: 5.6, w: 7.5, h: 1.7
  });

  s.addShape(pres.shapes.RECTANGLE, {
    x: 8.4, y: 1.5, w: 4.5, h: 5.7, fill: { color: C.forest }, line: { color: C.forest }
  });
  s.addShape(pres.shapes.RECTANGLE, {
    x: 8.4, y: 1.5, w: 0.12, h: 5.7, fill: { color: C.accent }, line: { color: C.accent }
  });

  s.addText("KEY POLICY FINDINGS", {
    x: 8.7, y: 1.7, w: 4.0, h: 0.35, fontSize: 11, fontFace: "Calibri",
    color: C.moss, bold: true, charSpacing: 4, margin: 0
  });

  s.addText([
    { text: "NY State+Local lands", options: { bold: true, breakLine: true, color: C.white, fontSize: 16 } },
    { text: "→ 17.5% LS+OG = 583 K ac", options: { breakLine: true, color: C.cream, fontSize: 13 } },
    { text: "More than ME has across all owners.", options: { color: C.cream, italic: true, fontSize: 11, breakLine: true } },
    { text: " ", options: { breakLine: true } },
    { text: "Public concentration", options: { bold: true, breakLine: true, color: C.white, fontSize: 16 } },
    { text: "→ ME federal 36% vs private 14%", options: { breakLine: true, color: C.cream, fontSize: 13 } },
    { text: "→ NH federal 51% vs private 21%", options: { breakLine: true, color: C.cream, fontSize: 13 } },
    { text: "→ VT federal 45% vs private 26%", options: { color: C.cream, fontSize: 13, breakLine: true } },
    { text: " ", options: { breakLine: true } },
    { text: "Where total acres live", options: { bold: true, breakLine: true, color: C.white, fontSize: 16 } },
    { text: "Private LS+OG total ~987 K ac across NE", options: { breakLine: true, color: C.cream, fontSize: 13 } },
    { text: "the natural target for PES / easements", options: { color: C.cream, italic: true, fontSize: 11 } }
  ], { x: 8.7, y: 2.1, w: 4.0, h: 5.0, fontFace: "Calibri", paraSpaceAfter: 2, margin: 0 });

  s.addNotes("Design-based EXPNS-weighted estimation, post-stratified through POP_PLOT_STRATUM_ASSGN and POP_STRATUM. NY State+Local lands stand out as the largest single LSOG pool by far. Private timberland is where most acres live, so PES or easement programs on private land are the policy lever with the most surface area.");
}

// ---- Slide 7: Carbon ----
{
  let s = pres.addSlide();
  addContentTitle(s, "Carbon: OG Plots Store 2.6-3.6× the Live Carbon of Not-LSOG",
    "Direct LD 1529 climate-mandate relevance");

  s.addImage({
    path: path.join(FIG, "figures/extras/fig10_carbon_by_class.png"),
    x: 0.5, y: 1.5, w: 8.5, h: 4.4
  });

  s.addShape(pres.shapes.RECTANGLE, {
    x: 9.4, y: 1.5, w: 3.5, h: 4.4, fill: { color: C.white }, line: { color: C.light_g, width: 1 }
  });
  s.addShape(pres.shapes.RECTANGLE, {
    x: 9.4, y: 1.5, w: 0.12, h: 4.4, fill: { color: C.forest }, line: { color: C.forest }
  });

  s.addText("MAINE", {
    x: 9.65, y: 1.65, w: 3.2, h: 0.35, fontSize: 11, fontFace: "Calibri",
    color: C.moss, bold: true, charSpacing: 4, margin: 0
  });
  s.addText("Live aboveground carbon", {
    x: 9.65, y: 1.97, w: 3.2, h: 0.3, fontSize: 10, fontFace: "Calibri",
    color: C.muted, italic: true, margin: 0
  });

  const carbon = [
    ["Not LSOG", "39",  "Mg C/ha"],
    ["TLS",      "72",  "Mg C/ha"],
    ["LS",       "91",  "Mg C/ha"],
    ["OG",       "139", "Mg C/ha"]
  ];
  for (let i = 0; i < 4; i++) {
    const y = 2.4 + i * 0.85;
    const isOG = (i === 3);
    s.addText(carbon[i][0], {
      x: 9.65, y, w: 1.4, h: 0.5, fontSize: 13, fontFace: "Calibri",
      color: isOG ? C.accent : C.muted, bold: isOG, margin: 0
    });
    s.addText(carbon[i][1], {
      x: 11.0, y: y - 0.07, w: 1.0, h: 0.55, fontSize: 28,
      fontFace: "Georgia", color: isOG ? C.accent : C.forest, bold: true, margin: 0,
      align: "right"
    });
    s.addText(carbon[i][2], {
      x: 11.0, y: y + 0.5, w: 1.6, h: 0.2, fontSize: 9, fontFace: "Calibri",
      color: C.muted, italic: true, align: "right", margin: 0
    });
  }

  s.addShape(pres.shapes.RECTANGLE, {
    x: 0.5, y: 6.2, w: 12.4, h: 1.0, fill: { color: C.forest }, line: { color: C.forest }
  });
  s.addText("Protecting Maine's ~24 K ac of OG class preserves ~100 Mg C/ha MORE carbon than letting it revert to Not-LSOG. Across the broader 1.99 M ac LSOG pool, that's substantial avoided emissions in policy-relevant terms.",
    { x: 0.7, y: 6.2, w: 12.0, h: 1.0, fontSize: 13, fontFace: "Calibri",
      color: C.cream, italic: true, valign: "middle", margin: 0 });

  s.addNotes("Carbon comparisons use FIA CARBON_AG by class. The OG to Not-LSOG ratio is 3.6x. The bottom band is the policy-relevant interpretation: avoided emissions value scales with both carbon density and acreage. LD 1529 names climate co-benefits explicitly.");
}

// ---- Section divider: Validation & Outlook ----
addSectionDivider("Validation and Outlook", "PART 03").addNotes("We pivot from descriptive results to benchmarking and project status.");

// ---- Slide 8: Reference benchmarks ----
{
  let s = pres.addSlide();
  addContentTitle(s, "Validation Against Independent Products",
    "v5.1 fits within range of LiDAR, Bayesian, and USFS-official OG estimates");

  const headerOpts = { bold: true, fill: { color: C.forest }, color: C.cream,
                       fontSize: 12, fontFace: "Calibri", valign: "middle" };
  const cellOpts = { fontSize: 11, fontFace: "Calibri", color: C.ink, valign: "middle" };
  const accentCellOpts = { fontSize: 11, fontFace: "Calibri", color: C.accent, valign: "middle", bold: true };

  const rows = [
    [{ text: "Source", options: headerOpts },
     { text: "Coverage", options: headerOpts },
     { text: "any-LSOG / OG share", options: headerOpts },
     { text: "Phase 7 kappa vs v5.1", options: headerOpts }],
    [{ text: "v5.1 (this work)", options: { ...cellOpts, bold: true } },
     { text: "All ME private + public", options: cellOpts },
     { text: "ME 14% any LSOG, 0.19% OG", options: accentCellOpts },
     { text: "—", options: cellOpts }],
    [{ text: "Hagan et al. 2024 LiDAR", options: cellOpts },
     { text: "Maine UT only (9.5 M ac)", options: cellOpts },
     { text: "21.4% LSOG, 1.0% OG (95 K ac)", options: cellOpts },
     { text: "BLOCKED (raster pending)", options: { ...cellOpts, color: C.muted, italic: true } }],
    [{ text: "Bruening 2026 (ORNL 2498)", options: cellOpts },
     { text: "Statewide MOG-prob > 50", options: cellOpts },
     { text: "~33% mature, 0.13% OG", options: cellOpts },
     { text: "kappa ~0 on OG-class", options: accentCellOpts }],
    [{ text: "Pelz 2023 (FEM 549)", options: cellOpts },
     { text: "NE NFS lands (~1 M ac)", options: cellOpts },
     { text: "10.1% Pelz-OG of NFS plots", options: cellOpts },
     { text: "0.25 LS+OG vs Pelz-OG", options: { ...accentCellOpts, color: C.forest } }],
    [{ text: "TreeMap (this work, v2)", options: cellOpts },
     { text: "Maine wall-to-wall 30 m", options: cellOpts },
     { text: "8.0-8.2% any-LSOG", options: cellOpts },
     { text: "—", options: { ...cellOpts, color: C.muted, italic: true } }]
  ];

  s.addTable(rows, {
    x: 0.5, y: 1.6, w: 12.4, h: 4.5, colW: [3.0, 3.0, 3.4, 3.0],
    rowH: 0.65, border: { pt: 1, color: "DDDDDD" }
  });

  s.addShape(pres.shapes.RECTANGLE, {
    x: 0.5, y: 6.3, w: 12.4, h: 1.0, fill: { color: C.forest }, line: { color: C.forest }
  });
  s.addText("Take-away: v5.1 LS+OG combined has fair agreement (κ ≈ 0.25) with Pelz's USFS-official OG criteria. The OG-specific class is poorly validated across all independent products (κ ~0). For policy reporting, LS+OG combined is the most stable category.",
    { x: 0.7, y: 6.3, w: 12.0, h: 1.0, fontSize: 13, fontFace: "Calibri",
      color: C.cream, italic: true, valign: "middle", margin: 0 });

  s.addNotes("Anchor table for the validation story. v5.1 is calibrated within range of LiDAR (Hagan), Bayesian (ORNL 2498), and USFS-official (Pelz) products. The OG-specific class is the least stable across products, which is consistent with the rarity of true OG plots in FIA. Defend our choice to lean on LS+OG combined for policy reporting.");
}

// ---- Slide 9: Wall-to-wall map ----
{
  let s = pres.addSlide();
  addContentTitle(s, "Wall-to-Wall: Maine 2020 / 2022 via TreeMap × FIA Imputation",
    "Phase 8 v2 closes the Unknown coverage gap to 0.33% via 1999-2023 panel lookup");

  s.addImage({
    path: path.join(FIG, "figures/map1_maine_plot_class.png"),
    x: 0.5, y: 1.5, w: 6.0, h: 5.7,
    sizing: { type: "contain", w: 6.0, h: 5.7 }
  });

  s.addShape(pres.shapes.RECTANGLE, {
    x: 7.0, y: 1.6, w: 5.9, h: 5.6, fill: { color: C.white }, line: { color: C.light_g, width: 1 }
  });
  s.addShape(pres.shapes.RECTANGLE, {
    x: 7.0, y: 1.6, w: 0.12, h: 5.6, fill: { color: C.forest }, line: { color: C.forest }
  });

  s.addText("MAINE TREEMAP RESULTS", {
    x: 7.3, y: 1.8, w: 5.4, h: 0.35, fontSize: 12, fontFace: "Calibri",
    color: C.moss, bold: true, charSpacing: 4, margin: 0
  });

  const tmRows = [
    [{ text: "Year", options: { bold: true, fill: { color: C.cream }, fontSize: 12 } },
     { text: "Class", options: { bold: true, fill: { color: C.cream }, fontSize: 12 } },
     { text: "Acres", options: { bold: true, fill: { color: C.cream }, fontSize: 12 } },
     { text: "% pixels", options: { bold: true, fill: { color: C.cream }, fontSize: 12 } }],
    ["2020", "Trans LS", "1.25 M", "7.5%"],
    ["2020", "LS", "118 K", "0.7%"],
    ["2020", "Not LSOG", "15.30 M", "91.5%"],
    ["2022", "Trans LS", "1.23 M", "7.4%"],
    ["2022", "LS", "113 K", "0.7%"],
    ["2022", "Not LSOG", "15.29 M", "91.6%"]
  ];
  s.addTable(tmRows, {
    x: 7.3, y: 2.25, w: 5.4, h: 3.2, colW: [0.9, 1.6, 1.6, 1.3],
    fontSize: 11, fontFace: "Calibri", color: C.ink,
    border: { pt: 0.5, color: "EEEEEE" }
  });

  s.addText([
    { text: "Why ME 8% < v5.1 plot-based 14%", options: { bold: true, breakLine: true, color: C.forest, fontSize: 13 } },
    { text: "Phase 8 v2 uses v4-style scoring (no Potapov GEDI canopy height), since the Potapov product is single-year 2019 and not applicable to plots from older FIA panels. Phase 8 v3 (Potapov-aware wall-to-wall) is the natural next step.",
      options: { color: C.muted, fontSize: 11, italic: true } }
  ], { x: 7.3, y: 5.5, w: 5.4, h: 1.6, fontFace: "Calibri", margin: 0, paraSpaceAfter: 4 });

  s.addNotes("Phase 8 imputes v4 scores back to TreeMap pixels through PLT_CN. Maine 2020 wall-to-wall: 1.36 M ac LSOG (8.2% of forested pixels). The 8% TreeMap-based vs 14% plot-based gap is real and explained by the missing GEDI-canopy-height dimension in v4 scoring. NE-wide v3 (recently completed) extends this to NH/VT/NY at 16, 16, and 14 percent.");
}

// ---- Slide 10: Pelz validation ----
{
  let s = pres.addSlide();
  addContentTitle(s, "Phase 7: Pelz 2023 Cross-Validation on NE NFS Lands",
    "Independent test using USFS-official Eastern Region OG criteria");

  s.addText("CONFUSION MATRIX (925 NFS plots in unified table)", {
    x: 0.5, y: 1.55, w: 6.5, h: 0.35, fontSize: 12, fontFace: "Calibri",
    color: C.moss, bold: true, charSpacing: 2, margin: 0
  });

  const confRows = [
    [{ text: "v5.1 class", options: { bold: true, fill: { color: C.forest }, color: C.cream, fontSize: 12 } },
     { text: "Not Pelz-OG", options: { bold: true, fill: { color: C.forest }, color: C.cream, fontSize: 12 } },
     { text: "Pelz-OG", options: { bold: true, fill: { color: C.forest }, color: C.cream, fontSize: 12 } },
     { text: "Total", options: { bold: true, fill: { color: C.forest }, color: C.cream, fontSize: 12 } }],
    ["Not LSOG", "467", "36", "503"],
    ["Transitioning LS", "314", "49", "363"],
    ["LS", "31", "24", "55"],
    ["OG", "1", "3", "4"],
    [{ text: "Total", options: { bold: true } }, "813", "112", "925"]
  ];

  s.addTable(confRows, {
    x: 0.5, y: 1.95, w: 6.5, h: 3.5, colW: [2.0, 1.7, 1.4, 1.4],
    fontSize: 12, fontFace: "Calibri", color: C.ink,
    border: { pt: 0.5, color: "DDDDDD" }, valign: "middle"
  });

  s.addShape(pres.shapes.RECTANGLE, {
    x: 7.4, y: 1.55, w: 5.5, h: 3.9, fill: { color: C.white }, line: { color: C.light_g, width: 1 }
  });
  s.addShape(pres.shapes.RECTANGLE, {
    x: 7.4, y: 1.55, w: 0.12, h: 3.9, fill: { color: C.forest }, line: { color: C.forest }
  });

  s.addText("COHEN'S KAPPA", {
    x: 7.65, y: 1.7, w: 5.0, h: 0.35, fontSize: 12, fontFace: "Calibri",
    color: C.moss, bold: true, charSpacing: 4, margin: 0
  });

  const kappas = [
    ["v5.1 OG vs Pelz OG",         "0.044", "essentially random",  C.muted],
    ["v5.1 LS+OG vs Pelz OG",      "0.253", "fair agreement",       C.forest],
    ["v5.1 any-LSOG vs Pelz OG",   "0.115", "slight",               C.muted]
  ];
  for (let i = 0; i < 3; i++) {
    const y = 2.2 + i * 1.0;
    s.addText(kappas[i][0], {
      x: 7.65, y, w: 3.4, h: 0.4, fontSize: 12, fontFace: "Calibri",
      color: kappas[i][3], bold: i === 1, margin: 0
    });
    s.addText(kappas[i][1], {
      x: 11.1, y: y - 0.05, w: 1.6, h: 0.5, fontSize: 22, fontFace: "Georgia",
      color: kappas[i][3], bold: true, align: "right", margin: 0
    });
    s.addText(kappas[i][2], {
      x: 7.65, y: y + 0.4, w: 5.1, h: 0.3, fontSize: 10, fontFace: "Calibri",
      color: C.muted, italic: true, margin: 0
    });
  }

  s.addShape(pres.shapes.RECTANGLE, {
    x: 0.5, y: 5.7, w: 12.4, h: 1.6, fill: { color: C.forest }, line: { color: C.forest }
  });
  s.addText("OG-share estimates differ by 25× across products on NE NFS plots", {
    x: 0.7, y: 5.85, w: 12.0, h: 0.35, fontSize: 13, fontFace: "Calibri",
    color: C.moss, bold: true, charSpacing: 2, margin: 0
  });

  const callouts = [
    ["v5.1",     "0.4%", C.white],
    ["Hagan UT", "1.0%", C.cream],
    ["Pelz R9",  "10.1%", C.accent]
  ];
  for (let i = 0; i < 3; i++) {
    const x = 0.9 + i * 4.1;
    s.addText(callouts[i][0], {
      x, y: 6.25, w: 3.5, h: 0.3, fontSize: 12, fontFace: "Calibri",
      color: C.cream, italic: true, margin: 0
    });
    s.addText(callouts[i][1], {
      x, y: 6.5, w: 3.5, h: 0.7, fontSize: 36, fontFace: "Georgia",
      color: callouts[i][2], bold: true, margin: 0
    });
  }

  s.addNotes("Pelz cross-validation on 925 NFS plots in our unified table. LS+OG combined kappa = 0.25 is fair agreement, which is the best independent validation we have. OG-only kappa essentially random reinforces that the OG-specific class is hard to nail down across products. The 0.4 / 1.0 / 10.1 percent OG-share comparison illustrates how strongly the choice of methodology drives the answer.");
}

// ---- Slide 11a: SILC / Hagan validation (Pingree) - results ----
{
  let s = pres.addSlide();
  addContentTitle(s, "Phase 9: Seven Islands LiDAR Validation",
    "Pingree Ownership cross-validation against Hagan M2V2b GFW23-masked raster (n = 125 plots)");

  // Share comparison table on left
  s.addText("SHARE-LEVEL COMPARISON (in-extent latest panel, n = 125)", {
    x: 0.5, y: 1.55, w: 7.5, h: 0.35, fontSize: 12, fontFace: "Calibri",
    color: C.moss, bold: true, charSpacing: 2, margin: 0
  });

  const shareRows = [
    [{ text: "Source", options: { bold: true, fill: { color: C.forest }, color: C.cream, fontSize: 11 } },
     { text: "any-LSOG", options: { bold: true, fill: { color: C.forest }, color: C.cream, fontSize: 11 } },
     { text: "LS+OG", options: { bold: true, fill: { color: C.forest }, color: C.cream, fontSize: 11 } },
     { text: "OG-only", options: { bold: true, fill: { color: C.forest }, color: C.cream, fontSize: 11 } }],
    ["v5.1 (FIA + GEDI)",       "8.0%",  "0.8%", "0.0%"],
    ["v4 (FIA, no GEDI)",       "16.8%", "1.6%", "0.0%"],
    [{ text: "Hagan at FIA plots", options: { bold: true, color: C.accent } },
     { text: "20.0%", options: { bold: true, color: C.accent } },
     { text: "1.6%",  options: { bold: true, color: C.accent } },
     { text: "0.8%",  options: { bold: true, color: C.accent } }],
    ["Hagan landscape Pingree", "18.8%", "2.4%", "0.6%"]
  ];
  s.addTable(shareRows, {
    x: 0.5, y: 1.95, w: 7.5, h: 2.4, colW: [3.0, 1.6, 1.5, 1.4],
    fontSize: 12, fontFace: "Calibri", color: C.ink,
    border: { pt: 0.5, color: "DDDDDD" }, valign: "middle"
  });

  // Confusion matrix
  s.addText("CONFUSION MATRIX  v5.1 (rows) x Hagan (cols)", {
    x: 0.5, y: 4.55, w: 7.5, h: 0.35, fontSize: 12, fontFace: "Calibri",
    color: C.moss, bold: true, charSpacing: 2, margin: 0
  });

  const cmRows = [
    [{ text: "v5.1", options: { bold: true, fill: { color: C.forest }, color: C.cream, fontSize: 11 } },
     { text: "Not LS", options: { bold: true, fill: { color: C.forest }, color: C.cream, fontSize: 11 } },
     { text: "Trans LS", options: { bold: true, fill: { color: C.forest }, color: C.cream, fontSize: 11 } },
     { text: "LS", options: { bold: true, fill: { color: C.forest }, color: C.cream, fontSize: 11 } },
     { text: "OG-like", options: { bold: true, fill: { color: C.forest }, color: C.cream, fontSize: 11 } }],
    ["Not LSOG", "93", "21", "1", "0"],
    ["Trans LS", "7", "1", "0", "1"],
    ["LS", "0", "1", "0", "0"],
    ["OG", "0", "0", "0", "0"]
  ];
  s.addTable(cmRows, {
    x: 0.5, y: 4.95, w: 7.5, h: 1.9, colW: [2.0, 1.4, 1.5, 1.3, 1.3],
    fontSize: 11, fontFace: "Calibri", color: C.ink,
    border: { pt: 0.5, color: "DDDDDD" }, valign: "middle"
  });

  // Right panel: kappa box and key insight
  s.addShape(pres.shapes.RECTANGLE, {
    x: 8.4, y: 1.55, w: 4.5, h: 5.3, fill: { color: C.forest }, line: { color: C.forest }
  });
  s.addShape(pres.shapes.RECTANGLE, {
    x: 8.4, y: 1.55, w: 0.12, h: 5.3, fill: { color: C.accent }, line: { color: C.accent }
  });

  s.addText("COHEN KAPPA", {
    x: 8.7, y: 1.7, w: 4.0, h: 0.35, fontSize: 12, fontFace: "Calibri",
    color: C.moss, bold: true, charSpacing: 4, margin: 0
  });

  const kappas = [
    ["v5.1 any-LSOG vs Hagan any-LS", "0.07"],
    ["v5.1 LS+OG vs Hagan LS+OG-like", "-0.01"],
    ["v4 any-LSOG vs Hagan any-LS",  "-0.01"]
  ];
  for (let i = 0; i < 3; i++) {
    const y = 2.2 + i * 0.85;
    s.addText(kappas[i][0], {
      x: 8.7, y, w: 3.2, h: 0.4, fontSize: 11, fontFace: "Calibri",
      color: C.cream, margin: 0
    });
    s.addText(kappas[i][1], {
      x: 11.7, y: y - 0.05, w: 1.1, h: 0.5, fontSize: 22, fontFace: "Georgia",
      color: C.cream, bold: true, align: "right", margin: 0
    });
  }

  s.addText([
    { text: "Aggregate share matches.", options: { bold: true, breakLine: true, color: C.white, fontSize: 14 } },
    { text: "Hagan at FIA plots = 20.0%", options: { breakLine: true, color: C.cream, fontSize: 11 } },
    { text: "Hagan landscape Pingree = 18.8%", options: { breakLine: true, color: C.cream, fontSize: 11 } },
    { text: " ", options: { breakLine: true } },
    { text: "Plot-by-plot agreement = random", options: { bold: true, breakLine: true, color: C.white, fontSize: 14 } },
    { text: "kappa near zero across all class boundaries", options: { color: C.cream, fontSize: 11, italic: true } }
  ], { x: 8.7, y: 5.0, w: 4.0, h: 1.85, fontFace: "Calibri", margin: 0, paraSpaceAfter: 2 });

  // Bottom callout — the FIA-plot sample is unbiased
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0.5, y: 7.0, w: 12.4, h: 0.45, fill: { color: C.moss }, line: { color: C.moss }
  });
  s.addText("FIA plot sample is representative of Pingree (Hagan-at-plots 20.0% closely matches Hagan-landscape 18.8%)",
    { x: 0.5, y: 7.0, w: 12.4, h: 0.45, fontSize: 13, fontFace: "Calibri",
      color: C.ink, bold: true, align: "center", valign: "middle", margin: 0 });

  s.addNotes("Phase 9 cross-validation against the Hagan M2V2b raster shared by Seven Islands. 6,275 ME plots sampled; 125 fall in Pingree's in-extent forest pixels in the latest panel. Aggregate share comparison is informative: Hagan-at-plots 20.0% matches Hagan-landscape 18.8% within tolerance, confirming the FIA plot sample is unbiased on Pingree. v4 share (16.8%) is closer to Hagan than v5.1 (8.0%) is. But plot-by-plot kappa is random across all class boundaries, indicating the two products measure different aspects of forest condition. The mechanistic explanation comes on the next slide.");
}

// ---- Slide 11b: SILC / Hagan validation - mechanism (skid trails) ----
{
  let s = pres.addSlide();
  addContentTitle(s, "Why FIA-Proxy and LiDAR Disagree at the Plot Level",
    "Skid trails, selective harvest legacy, and what each method can and cannot see");

  // Two-panel layout: Hagan vs v5.1
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0.5, y: 1.55, w: 6.0, h: 5.3, fill: { color: C.white }, line: { color: C.light_g, width: 1 }
  });
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0.5, y: 1.55, w: 6.0, h: 0.55, fill: { color: C.forest }, line: { color: C.forest }
  });
  s.addText("HAGAN LIDAR PROTOCOL  (M2V2b)", {
    x: 0.7, y: 1.55, w: 5.6, h: 0.55, fontSize: 13, fontFace: "Calibri",
    color: C.cream, bold: true, charSpacing: 4, valign: "middle", margin: 0
  });
  s.addText([
    { text: "What it sees:", options: { bold: true, breakLine: true, color: C.forest, fontSize: 13 } },
    { text: "Eight 1-m LiDAR canopy metrics per hectare:", options: { breakLine: true, color: C.ink, fontSize: 11 } },
    { text: "mean / max / 95th-pct height, rugosity, rumple, cover fractions over 2/6/15 m.", options: { breakLine: true, color: C.muted, fontSize: 11, italic: true } },
    { text: " ", options: { breakLine: true } },
    { text: "Sensitive to:", options: { bold: true, breakLine: true, color: C.accent, fontSize: 13 } },
    { text: "Skid trails, harvest gaps, stump removal, light selective harvest.", options: { breakLine: true, color: C.ink, fontSize: 11 } },
    { text: "Canopy disturbance depresses rugosity and cover fractions.", options: { breakLine: true, color: C.muted, fontSize: 11, italic: true } },
    { text: " ", options: { breakLine: true } },
    { text: "What it misses:", options: { bold: true, breakLine: true, color: C.muted, fontSize: 13 } },
    { text: "Tree-level changes (large-tree removal, BA reduction, snag dynamics, age) when the residual canopy stays tall.", options: { color: C.ink, fontSize: 11 } }
  ], { x: 0.75, y: 2.25, w: 5.5, h: 4.5, fontFace: "Calibri", margin: 0, paraSpaceAfter: 2 });

  s.addShape(pres.shapes.RECTANGLE, {
    x: 6.8, y: 1.55, w: 6.0, h: 5.3, fill: { color: C.white }, line: { color: C.light_g, width: 1 }
  });
  s.addShape(pres.shapes.RECTANGLE, {
    x: 6.8, y: 1.55, w: 6.0, h: 0.55, fill: { color: C.moss }, line: { color: C.moss }
  });
  s.addText("v5.1 FIA-PROXY CLASSIFIER", {
    x: 7.0, y: 1.55, w: 5.6, h: 0.55, fontSize: 13, fontFace: "Calibri",
    color: C.ink, bold: true, charSpacing: 4, valign: "middle", margin: 0
  });
  s.addText([
    { text: "What it sees:", options: { bold: true, breakLine: true, color: C.forest, fontSize: 13 } },
    { text: "FIA tree-level subplot data plus Potapov GEDI 30 m canopy height.", options: { breakLine: true, color: C.ink, fontSize: 11 } },
    { text: "Large-tree BA, total BA, snag TPA, structural SD of DBH, stand age, RH95.", options: { breakLine: true, color: C.muted, fontSize: 11, italic: true } },
    { text: " ", options: { breakLine: true } },
    { text: "Sensitive to:", options: { bold: true, breakLine: true, color: C.accent, fontSize: 13 } },
    { text: "Tree-level harvest signal: big trees removed, BA depressed, age clock reset.", options: { breakLine: true, color: C.ink, fontSize: 11 } },
    { text: "Captures change even when canopy structure persists.", options: { breakLine: true, color: C.muted, fontSize: 11, italic: true } },
    { text: " ", options: { breakLine: true } },
    { text: "What it misses:", options: { bold: true, breakLine: true, color: C.muted, fontSize: 13 } },
    { text: "Skid-trail and harvest-gap effects within the hectare but outside the FIA subplot. The subplot may not overlap the disturbed pixels.", options: { color: C.ink, fontSize: 11 } }
  ], { x: 7.05, y: 2.25, w: 5.5, h: 4.5, fontFace: "Calibri", margin: 0, paraSpaceAfter: 2 });

  // Bottom: synthesis
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0.5, y: 7.0, w: 12.4, h: 0.5, fill: { color: C.forest }, line: { color: C.forest }
  });
  s.addText("Both methods are imperfect on heavily managed industrial timberland. They measure genuinely different signals.",
    { x: 0.5, y: 7.0, w: 12.4, h: 0.5, fontSize: 13, fontFace: "Calibri",
      color: C.cream, bold: true, italic: true, align: "center", valign: "middle", margin: 0 });

  s.addNotes("Mechanistic explanation. Hagan's RAP-style ground assessment, per Ryan, is heavily dependent on skid trails and stumps; the LiDAR raster inherits that sensitivity through the canopy-rugosity and cover-fraction metrics. FIA tree-level data does not record skid trails directly. Conversely, FIA records tree-level changes from selective harvest that LiDAR canopy metrics may miss when residual canopy stays tall. The two methods diverge plot-by-plot precisely because of these complementary blind spots. This is the kind of finding that motivates pairing FIA with LiDAR rather than treating either as ground truth alone.");
}

// ---- Slide 11: Limitations ----
{
  let s = pres.addSlide();
  addContentTitle(s, "Limitations & Caveats",
    "Read every estimate alongside its weakness");

  const limits = [
    ["1", "OG-class precision is low",
     "v5.1 OG kappa ≈ 0 vs Pelz, ORNL, and Hagan. The four v5.1 OG plots may not match the OG-class calls of any independent product. Don't over-interpret state-level OG percentages."],
    ["2", "FIA-proxy and LiDAR diverge plot-by-plot (Phase 9)",
     "Pingree cross-validation: aggregate share matches (v4 16.8% ≈ Hagan 18.8%) but plot-by-plot kappa is random. Skid trails depress Hagan canopy metrics; FIA tree-level data may not record them. Both methods are imperfect on managed timberland."],
    ["3", "FIA plot fuzzing limits cell-level analysis",
     "Public FIA lat/lon are fuzzed up to ~1 km. For 30 m / 100 m raster extractions this introduces small but systematic noise. DUA true coordinates would tighten this; buffered modal sampling does not change kappa estimates."],
    ["4", "Full Maine UT Hagan raster still not available",
     "Seven Islands shared the Pingree raster (290 K ha, n=125 plots). The 4.2 M ha UT raster would expand the LS-class and OG-class samples beyond n=1 and n=1 respectively in the Hagan reference."],
    ["5", "ORNL 2498 trains on FIA labels",
     "Bruening et al. 2026 use FIA MOG labels as response variable. Cross-validation is therefore a coherence check, not blind validation."]
  ];

  for (let i = 0; i < limits.length; i++) {
    const y = 1.55 + i * 1.05;
    s.addShape(pres.shapes.OVAL, {
      x: 0.5, y, w: 0.65, h: 0.65, fill: { color: C.forest }, line: { color: C.forest }
    });
    s.addText(limits[i][0], {
      x: 0.5, y, w: 0.65, h: 0.65, fontSize: 22, fontFace: "Georgia",
      color: C.cream, bold: true, align: "center", valign: "middle", margin: 0
    });
    s.addText(limits[i][1], {
      x: 1.35, y: y - 0.05, w: 11.5, h: 0.4, fontSize: 16, fontFace: "Georgia",
      color: C.forest, bold: true, margin: 0
    });
    s.addText(limits[i][2], {
      x: 1.35, y: y + 0.32, w: 11.5, h: 0.7, fontSize: 12, fontFace: "Calibri",
      color: C.ink, margin: 0
    });
  }

  s.addNotes("Honest limitations. Item 1 is the most important caveat for any audience using OG numbers. Item 2 is the Phase 9 finding — the divergence between FIA-proxy and LiDAR is mechanistic, not an error in either product. Worth pausing on with SILC and other LiDAR collaborators: pairing the two methods is the right answer.");
}

// ---- Slide 12: Next steps ----
{
  let s = pres.addSlide();
  addContentTitle(s, "Project Status and Next Steps",
    "37+ commits on github.com/holoros/lsog-ne; Pingree Hagan validation delivered (Phase 9)");

  const cols = [
    { title: "DELIVERED",
      color: C.forest,
      items: [
        "v5.1 operational classifier",
        "Multi-state regional run (ME/NH/VT/NY)",
        "Bootstrap and FIA design-based CIs",
        "Ownership, carbon, forest-type breakdowns",
        "Pelz cross-validation (Phase 7)",
        "Seven Islands Hagan validation (Phase 9)",
        "TreeMap NE wall-to-wall + Potapov (Phase 8)",
        "Manuscript V1 first complete draft"
      ] },
    { title: "QUEUED  UNBLOCKED",
      color: C.moss,
      items: [
        "State-specific RH95 thresholds",
        "Maine UT polygon-based filter",
        "rFIA design-package cross-validation",
        "GEDI L2A direct integration",
        "DUA true-coordinate refinement",
        "Manuscript V2: reconcile intro numbers",
        "Extend to MA / CT / RI"
      ] },
    { title: "BLOCKED  /  PARTIAL",
      color: C.accent,
      items: [
        "Full Maine UT Hagan raster",
        "  Pingree available via Seven Islands",
        "  4.2 M ha UT-wide still pending",
        " ",
        "Acquisition routes:",
        ">> Our Climate Common",
        ">> LD 1529 / DACF working group"
      ] }
  ];

  // Layout: 3 columns of width 4.0, gap 0.20, total = 12.6, centered with x=0.35
  for (let i = 0; i < 3; i++) {
    const x = 0.35 + i * 4.20;
    const c = cols[i];

    s.addShape(pres.shapes.RECTANGLE, {
      x, y: 1.55, w: 4.0, h: 5.4, fill: { color: C.white },
      line: { color: C.light_g, width: 1 }
    });
    s.addShape(pres.shapes.RECTANGLE, {
      x, y: 1.55, w: 4.0, h: 0.55, fill: { color: c.color }, line: { color: c.color }
    });
    s.addText(c.title, {
      x: x + 0.2, y: 1.55, w: 3.7, h: 0.55, fontSize: 13, fontFace: "Calibri",
      color: C.cream, bold: true, charSpacing: 4, valign: "middle", margin: 0
    });

    const itemList = c.items.map((it, idx) => ({
      text: it,
      options: { bullet: !(it.startsWith(" ") || it.startsWith(">>") || it.trim() === ""),
                 breakLine: idx < c.items.length - 1,
                 fontSize: 11, color: it.startsWith(" ") ? C.muted : C.ink,
                 italic: it.startsWith(">>") || it.startsWith(" "),
                 paraSpaceAfter: 4 }
    }));
    s.addText(itemList, {
      x: x + 0.25, y: 2.25, w: 3.6, h: 4.6, fontFace: "Calibri",
      margin: 0, valign: "top"
    });
  }

  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 7.05, w: 13.3, h: 0.45, fill: { color: C.forest }, line: { color: C.forest }
  });
  s.addText("Repo: github.com/holoros/lsog-ne   |   Cardinal: /users/PUOM0008/crsfaaron/LSOG/   |   Memory file: CLAUDE.md", {
    x: 0.5, y: 7.05, w: 12.4, h: 0.45, fontSize: 11, fontFace: "Consolas",
    color: C.cream, valign: "middle", margin: 0
  });

  s.addNotes("Project-status board. Phase 8 v3 NE wall-to-wall just landed (commit 9d0468b) and is reflected in the DELIVERED column. The single biggest blocker remains Hagan raster acquisition. Three plausible paths to that raster are listed.");
}

// Write
pres.writeFile({ fileName: "/sessions/modest-sweet-archimedes/mnt/ME/LSOG_cardinal_setup/Northeast_LSOG_Project.pptx" })
  .then(f => console.log("Wrote: " + f));
