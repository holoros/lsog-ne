const fs = require("fs");
const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell, ImageRun,
        Header, Footer, AlignmentType, BorderStyle, WidthType, ShadingType, VerticalAlign,
        HeadingLevel, TableOfContents, PageNumber, PageBreak, TabStopType, LeaderType } = require("docx");

const MD  = "/sessions/vibrant-lucid-faraday/mnt/outputs/mfpc_report.md";
const FIG = "/sessions/vibrant-lucid-faraday/mnt/outputs";
const src = fs.readFileSync(MD, "utf8").split("\n");

// Unicode sub/superscript + symbol normalizer applied to all text
function S(t){ t = String(t)
  .replace(/CO2e/g,"CO₂e").replace(/CO2/g,"CO₂")
  .replace(/m\^3/g,"m³").replace(/m3\b/g,"m³")
  .replace(/ft\^2/g,"ft²").replace(/km\^2/g,"km²")
  .replace(/R\^2/g,"R²").replace(/ha\^-1/g,"ha⁻¹")
  .replace(/>=/g,"≥").replace(/<=/g,"≤")
  .replace(/\+\/-/g,"±").replace(/\+-/g,"±"); t = t.split(/(\s+)/).map(function(w){return /https?:\/\/|doi\.org/.test(w)?w:w.replace(/(\d)-(\d)/g,"$1\u2013$2");}).join(""); return t; }
const BLUE = "1A3D28", LT = "E2EAE4", GOLD = "C5A55A";  // CRSF brand: forest green, light-green tint, gold accent
const border = { style: BorderStyle.SINGLE, size: 1, color: "AAB7BD" };
const borders = { top: border, bottom: border, left: border, right: border };
function tc(text, w, head){
  const t=String(text).trim();
  const conf = (!head && (t==="High"||t==="Medium"||t==="Low"));
  let fill = head ? LT : undefined;
  if(conf) fill = (t==="High")?"C6EFCE":(t==="Medium")?"FFEB9C":"FFC7CE";
  return new TableCell({ borders, width:{size:w,type:WidthType.DXA},
    shading: fill?{fill:fill,type:ShadingType.CLEAR,color:"auto"}:undefined,
    verticalAlign: VerticalAlign.CENTER,
    margins:{top:60,bottom:60,left:110,right:110},
    children:[new Paragraph({alignment:AlignmentType.CENTER, children:[new TextRun({text:S(t),bold:!!head||conf,size:19})]})] }); }
function table(rows, widths){ const tot=widths.reduce((a,b)=>a+b,0);
  return new Table({ width:{size:tot,type:WidthType.DXA}, columnWidths:widths,
    rows: rows.map((r,ri)=>new TableRow({cantSplit:true, children:r.map((c,ci)=>tc(c,widths[ci],ri===0))})) }); }
// Recommendations table with merged category header rows (no repeating category column)
function recCell(text, w, o){ o=o||{};
  const align=o.center?AlignmentType.CENTER:AlignmentType.LEFT; let fill=o.fill;
  if(o.priority){ const t=String(text).trim(); fill=(t==="High")?"C6EFCE":(t==="Medium")?"FFEB9C":"FFC7CE"; }
  return new TableCell({ borders, width:{size:w,type:WidthType.DXA}, columnSpan:o.span||1,
    shading: fill?{fill:fill,type:ShadingType.CLEAR,color:"auto"}:undefined,
    verticalAlign: VerticalAlign.CENTER, margins:{top:70,bottom:70,left:130,right:130},
    children:[new Paragraph({alignment:align, children:[new TextRun({text:S(text), bold:!!o.bold, color:o.color, size:19})]})] }); }
function recsTable(){
  const RW=7860, PW=1500, FULL=RW+PW;
  const DATA=[
    ["Accounting and reporting",[
      ["State LSOG extent as a design-based range with its sampling interval, anchored to the FIA estimate (late-successional-plus-old-growth 14.1% [12.9-15.3] of forestland); drop single-percentage headlines.","High"],
      ["Treat the combined late-successional-plus-old-growth class as the policy unit, and rely on measured structure rather than FIA stand age.","High"],
      ["Separate the gross harvest flux from the net older-forest stock wherever a loss rate is cited, because they point in opposite directions here.","Medium"]]],
    ["Mapping and validation",[
      ["Field-verify the old-growth class against an independent probability sample, blind to the map, before any parcel is acquired, using the documented old-growth stands and reserves as anchors.","High"],
      ["Cross-check any single map against at least one independent product and report locational agreement (Cohen's kappa), not only the percentage.","High"],
      ["Carry classification uncertainty into the parcel ranking; rank from a probability surface, not from a single binary map.","High"],
      ["State the grain at which any percentage is produced, and hold resolution fixed in any map-to-map or map-to-inventory comparison.","Medium"],
      ["Adopt forest-type and ecoregion-specific structural criteria rather than one canopy threshold, so low-stature spruce-fir, cedar, and peatland old-growth are not missed.","Medium"]]],
    ["Conservation strategy",[
      ["Pursue representation of the late-successional condition across the region's forest types and ecoregions rather than per-state parity.","High"],
      ["Engage private working-forest owners as partners through easements, payments for ecosystem services, and targeted reserves.","High"],
      ["Protect the documented high-value old-growth stands now, while the broader accounting matures.","Medium"]]]
  ];
  const rows=[ new TableRow({tableHeader:true, children:[ recCell("Recommendation",RW,{bold:true,fill:LT,center:true}), recCell("Priority",PW,{bold:true,fill:LT,center:true}) ]}) ];
  for(const grp of DATA){
    rows.push(new TableRow({cantSplit:true, children:[ recCell(grp[0],FULL,{span:2,bold:true,fill:BLUE,color:"FFFFFF"}) ]}));
    for(const it of grp[1]) rows.push(new TableRow({cantSplit:true, children:[ recCell(it[0],RW,{}), recCell(it[1],PW,{priority:true,bold:true,center:true}) ]}));
  }
  return new Table({ width:{size:FULL,type:WidthType.DXA}, columnWidths:[RW,PW], rows:rows });
}
function P(text){
  text=S(text); const out=[]; let last=0, m; const re=/\*\*([^*]+)\*\*/g;
  while((m=re.exec(text))){ if(m.index>last) out.push(new TextRun({text:text.slice(last,m.index),size:22}));
    out.push(new TextRun({text:m[1],bold:true,size:22})); last=m.index+m[0].length; }
  if(last<text.length) out.push(new TextRun({text:text.slice(last),size:22}));
  if(!out.length) out.push(new TextRun({text:"",size:22}));
  const isTitle=/^\*\*Table/i.test(text);
  return new Paragraph({ alignment:AlignmentType.JUSTIFIED, spacing:{after:140,line:300}, keepNext:isTitle, keepLines:isTitle, children:out });
}

const children = [];

// ---- Title block (CRSF branded) ----
children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{before:700,after:240},
  children:[new ImageRun({ type:"png", data:fs.readFileSync(`${FIG}/crsf_logo.png`),
    transformation:{width:150,height:153}, altText:{title:"CRSF",description:"Center for Research on Sustainable Forests",name:"crsf"} })] }));
children.push(new Paragraph({ spacing:{before:120,after:120}, alignment:AlignmentType.CENTER,
  children:[new TextRun({text:"Late-Successional and Old-Growth Forest Across Northern New England", bold:true, size:40, color:BLUE})] }));
children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{after:160}, keepLines:true,
  children:[new TextRun({text:"What the Inventory Shows, and the Limits of LiDAR-Based Mapping", italics:true, size:26})] }));
children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{after:240},
  border:{bottom:{style:BorderStyle.SINGLE,size:14,color:GOLD,space:6}},
  children:[new TextRun({text:"",size:2})] }));
children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{after:80},
  children:[new TextRun({text:"A General Technical Assessment", bold:true, size:24})] }));
children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{after:60},
  children:[new TextRun({text:"Aaron Weiskittel", size:22})] }));
children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{after:40},
  children:[new TextRun({text:"Center for Research on Sustainable Forests, University of Maine", size:20, italics:true})] }));
children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{after:200},
  children:[new TextRun({text:"June 2026", size:20})] }));
children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{after:600}, keepLines:true,
  children:[new TextRun({text:"A general technical assessment prepared independently to inform the discussion of late-successional and old-growth forest in Maine and the region, including the LD 1529 process. It was not prepared for, or at the request of, any single organization.", italics:true, size:18, color:"666666"})] }));
children.push(new Paragraph({ children:[new PageBreak()] }));

// ---- TOC (static) ----
children.push(new Paragraph({ heading:HeadingLevel.HEADING_1, children:[new TextRun({text:"Contents"})] }));
const TOC=[["Executive summary","3"],["1.  Background","5"],
  ["2.  Primary limitations of the LiDAR analysis and the RAP protocol","5"],
  ["3.  Our primary findings: a regional, design-based account","14"],
  ["4.  Robustness: stress testing the conclusions","21"],
  ["5.  Implications for Maine policy and the regional forest economy","22"],
  ["6.  Recommendations","24"],["7.  Conclusions","25"],
  ["8.  Methods and data availability","25"],["9.  References","27"],
  ["Appendix: detailed results with 95% confidence intervals","29"]];
for (const [t,pg] of TOC){
  children.push(new Paragraph({ spacing:{after:90}, tabStops:[{type:TabStopType.RIGHT, position:9360, leader:LeaderType.DOT}],
    children:[new TextRun({text:t, size:22}), new TextRun({text:"\t"+pg, size:22})] }));
}
children.push(new Paragraph({ children:[new PageBreak()] }));

// ---- parse body ----
const KEYFIND_AFTER = "On the mapping itself";   // inject key-findings table after exec summary paragraph that starts here? we inject before section 1
let injectedKeyTable=false, injectedStress=false, injectedFig=false, firstH1Done=false;
for (let i=0;i<src.length;i++){
  let line = src[i].trim();
  if (line==="" || line==="---") continue;
  // stop title block lines already emitted
  if (line.startsWith("# ")) continue; // main title (handled)
  if (line.startsWith("## What the Inventory")) continue;
  if (line.startsWith("### A General Technical Assessment")) continue;
  if (line.startsWith("Aaron Weiskittel,")) continue;
  if (line.startsWith("June 2026.")) continue;
  if (line.startsWith("This is a general technical assessment")) continue;

  // markdown table block
  if (line.startsWith("|")){
    const block=[];
    while (i<src.length && src[i].trim().startsWith("|")){ block.push(src[i].trim()); i++; }
    i--;
    const rows=block.map(r=>r.split("|").slice(1,-1).map(c=>c.trim()))
                    .filter(r=>!r.every(c=>/^:?-+:?$/.test(c)||c===""));
    const ncol=rows[0].length;
    let widths;
    if(/Conf|Priority/i.test(rows[0][ncol-1])){ const cw=1500; const rest=Math.floor((9360-cw)/(ncol-1)); widths=Array(ncol-1).fill(rest).concat([cw]); widths[0]=9360-rest*(ncol-2)-cw; }
    else { const w=Math.floor(9360/ncol); widths=Array(ncol).fill(w); widths[0]=9360-w*(ncol-1); }
    children.push(table(rows, widths));
    children.push(new Paragraph({ spacing:{after:120}, children:[new TextRun({text:"",size:6})] }));
    continue;
  }

  if (line.startsWith("### ")){
    children.push(new Paragraph({ heading:HeadingLevel.HEADING_2, spacing:{before:160,after:80},
      children:[new TextRun({text:S(line.replace(/^###\s*/,""))})] }));
  } else if (line.startsWith("## ")){
    const h = S(line.replace(/^##\s*/,""));
    // The summary-of-findings table closes the Executive Summary; the page break comes after it.
    if (h.startsWith("1. Background") && !injectedKeyTable){
      children.push(new Paragraph({ heading:HeadingLevel.HEADING_2, spacing:{before:120,after:80}, children:[new TextRun({text:"Summary of primary findings"})] }));
      children.push(table([
        ["Question","Our finding (design-based, regional)","Confidence"],
        ["How much LSOG exists?","A range with sampling intervals, not a point: 12.5% [11.4-13.7] of Maine forestland by live large-tree structure and 14.1% [12.9-15.3] under the integrated structural proxy. Stand-age thresholds are a cross-check only.","High"],
        ["How sensitive to definition?","The same forest is ~3% LSOG (all four axes) to over 90% (one axis). The headline number is a definitional choice.","High"],
        ["Regional ranking","Maine carries the lowest integrated share; this is the expected signature of its production role in a regional triad, not a per-state deficit.","Medium"],
        ["Is it disappearing?","Net older-forest stock is stable to rising, 2003-2024. The cited loss rate is a gross harvest flux, not a declining net stock.","Medium"],
        ["Do the maps agree?","Independent credible maps disagree 1.6 to 2.6 fold in amount and agree on only a few percent of the specific ground.","High"],
      ], [2300,5560,1500]));
      children.push(new Paragraph({ spacing:{after:160}, keepLines:true, children:[new TextRun({text:"",size:8})] }));
      injectedKeyTable=true;
    }
    // start every top-level section on a fresh page (after the first)
    if (firstH1Done && /^1\. Background|^Appendix|^9\. References/.test(h)) children.push(new Paragraph({ children:[new PageBreak()] }));
    firstH1Done = true;
    children.push(new Paragraph({ heading:HeadingLevel.HEADING_1, spacing:{before:340,after:150},
      border:{ bottom:{ style:BorderStyle.SINGLE, size:8, color:GOLD, space:6 } },
      children:[new TextRun({text:h})] }));
  } else if (line==="RECOMMENDATIONS_TABLE_INJECT"){
    children.push(recsTable());
    children.push(new Paragraph({ spacing:{after:120}, children:[new TextRun({text:"",size:6})] }));
  } else {
    children.push(P(line));
    // inject ensemble + uncertainty figure after the §3.5 probability-surface paragraph
    if (line.startsWith("Rather than a single binary map")){
      children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{before:60,after:50},
        children:[new ImageRun({ type:"png", data:fs.readFileSync(`${FIG}/Fig_bestmap_fia_prob.png`),
          transformation:{width:560,height:391}, altText:{title:"FIA LSOG probability map",description:"design-based FIA plots colored by modeled LSOG probability",name:"bestmap"} })] }));
      children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{after:160}, keepLines:true,
        children:[new TextRun({text:"Figure 6. Our FIA-anchored LSOG estimate beside the reproduced published LiDAR model (Hagan et al. 2026) at the same plots, built from public FIA plot coordinates. (a) Each design-based plot colored by its modeled four-axis probability of LSOG (viridis, dark low to yellow high); the highest-probability plots concentrate in the north-central townships, while much of the southern and eastern forest carries low modeled probability. (b) The reproduced published random-forest classification sampled at the same plots: blue where the model calls LSOG, light blue where it calls Not LSOG, and grey where the plot falls outside the unorganized-townships study area the published map covers. The two methods broadly agree on the northern concentration of older forest, but the published map covers only the unorganized townships, and the comparison is over where each method places LSOG. The binary class drawn from our ensemble surface is design-calibrated so that its mapped area equals the FIA estimate (14.1% [12.9-15.3] integrated; 3.1% [2.5-3.7] four-axis), so the map does not over-claim relative to the inventory.", italics:true, size:18})] }));
      children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{before:60,after:50},
        children:[new ImageRun({ type:"png", data:fs.readFileSync(`${FIG}/msFig_sobol.png`),
          transformation:{width:560,height:237}, altText:{title:"Sobol sensitivity",description:"global sensitivity of ensemble probability with bootstrap CIs",name:"sobol"} })] }));
      children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{after:160}, keepLines:true,
        children:[new TextRun({text:"Figure 7. What the LSOG signal rests on. (a) Variance-based global sensitivity (Sobol indices) of the structural probability surface, with 300-replicate bootstrap 95% confidence intervals: canopy height accounts for nearly all of the explained variation (direct effect 0.88 [0.66 to 1.07]; total effect including interactions 0.95 [0.89 to 0.99]), while time since disturbance is a minor modifier (direct 0.05; total 0.12 [0.11 to 0.13]). A map keyed on canopy height alone is therefore resolving one dominant structural axis. (b) Cross-validated discrimination of the multi-axis any-LSOG class by remote-sensing attribute set: a single canopy-height product (Meta, AUC 0.668) sits at the bottom, and discrimination rises as complementary learned embeddings and disturbance history are added, reaching 0.872 for all four sources fused. The two panels together show why fusion outperforms any single canopy-height layer.", italics:true, size:18})] }));
      children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{before:60,after:50},
        children:[new ImageRun({ type:"png", data:fs.readFileSync(`${FIG}/v6_aoi_prob_mosaic_preview.png`),
          transformation:{width:560,height:287}, altText:{title:"full 10 m LSOG mosaic",description:"wall-to-wall 10 m LSOG probability over the full study area",name:"mosaic10m"} })] }));
      children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{after:160}, keepLines:true,
        children:[new TextRun({text:"Figure 8. The two wall-to-wall maps side by side over the study area, with county boundaries, Baxter State Park, and Big Reed Forest Reserve marked. (a) The reproduced published airborne-LiDAR classification (Hagan et al. 2026), with its late-successional and old-growth classes in blue (the pixels the prioritization treats as the conservation target). (b) Our fused 10-meter LSOG probability surface, forest-masked so non-forest and open water are removed (shown in grey) using the FIA nearest-neighbor forest/non-forest mask (Wilson et al. 2012, 2009 vintage), displayed at 100 meters; darker green is higher modeled probability. Both maps concentrate older forest in the north-central townships around Big Reed and Baxter, but our product is built at 10 meters (29,083 by 29,162 pixels, about 848 million cells) and resolves the small remnants a 1-hectare grid averages away. The forest-masked 10-meter probability raster, together with the full unmasked surface, is released openly at the Zenodo DOI.", italics:true, size:18})] }));
    }
    // inject Seven Islands (SILC) cross-comparison figure in §2.4
    if (line.startsWith("On Seven Islands Land Company timberland")){
      children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{before:60,after:50},
        children:[new ImageRun({ type:"png", data:fs.readFileSync(`${FIG}/silc_cross_comparison.png`),
          transformation:{width:625,height:322}, altText:{title:"Seven Islands cross-comparison",description:"SILC cross-map comparison",name:"silc"} })] }));
      children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{after:160}, keepLines:true,
        children:[new TextRun({text:"Figure 2. Cross-comparison on Seven Islands Land Company timberland, where an operational LSOG map already exists and was shared for this work, zoomed to the largest contiguous parcel (about 43,000 ha) so the per-pixel overlap is legible. The published classification and our independent FIA-anchored 10 m surface (the v5.1 structural classifier, our integrated multi-axis classifier described in Section 3) are compared on the same ground; across the full ownership they agree on only 6.4 percent of the land (both flag LSOG) and place LSOG in substantially different locations (Cohen's kappa 0.24 here, against 0.19 across the full study area).", italics:true, size:18})] }));
      // inject priority-uncertainty figure in §2.5
    }
    if (line.startsWith("The downstream prioritization delineates its patches")){
      children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{before:60,after:50},
        children:[new ImageRun({ type:"png", data:fs.readFileSync(`${FIG}/Fig_priority_uncertainty.png`),
          transformation:{width:600,height:353}, altText:{title:"priority uncertainty",description:"selection frequency and stability of prioritized set",name:"priority"} })] }));
      children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{after:160}, keepLines:true,
        children:[new TextRun({text:"Figure 3. Why a single map is a fragile basis for ranking parcels for acquisition. Using the published map's own across-model uncertainty, we re-drew the probability surface 200 times and re-ranked every parcel each time. The map at left shows how often each location lands in the top-priority 5 percent across those 200 draws: most of the landscape is selected only occasionally (pale) and very little is selected consistently (dark), so the highest-priority set is not stable. The histogram at right shows the overlap (Jaccard index) between the top-5-percent set from each draw and the top-5-percent set of the original single map: the overlap centers near 0.10, meaning roughly 90 percent of the parcels a one-map ranking would select change once the map's own uncertainty is carried through. This figure is about the stability of the ranking, not a comparison between maps; a program that ranks parcels from one binary map does not see this instability, whereas a probabilistic surface makes it explicit.", italics:true, size:18})] }));
    }
    // inject resolution-sensitivity figure in §2.8
    if (line.startsWith("Genuine old-growth in Maine survives largely as small remnants")){
      children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{before:60,after:50},
        children:[new ImageRun({ type:"png", data:fs.readFileSync(`${FIG}/resolution_curve.png`),
          transformation:{width:560,height:354}, altText:{title:"resolution sensitivity",description:"LSOG share versus mapping grain, two footprints",name:"resolution"} })] }));
      children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{after:160}, keepLines:true,
        children:[new TextRun({text:"Figure 5. Mapped LSOG share against mapping grain, from 10 m (the resolution of our fused product) to 200 m, for two footprints, with 300-replicate spatial block-bootstrap 95% confidence intervals (error bars). Over the Big Reed and Baxter showcase region the flagged share falls from about 22 percent at 10 m to about 17.5 percent at the 1-hectare grid the published map uses and about 15 percent at 200 m; over the full study area it falls from about 11 percent to about 5 percent. The decline is monotonic at both extents and the intervals are narrow, so the dependence on grain is a real, well-resolved effect rather than sampling noise. A percentage without its grain is incomplete, and two maps built at different resolutions are not directly comparable (Hayashi et al. 2016).", italics:true, size:18})] }));
    }
    // inject rare-class threshold figure after the §3.6 threshold paragraph
    if (line.startsWith("From this fused model we produce a 10-meter wall-to-wall")){
      children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{before:60,after:50},
        children:[new ImageRun({ type:"png", data:fs.readFileSync(`${FIG}/Fig_threshold_rareclass.png`),
          transformation:{width:560,height:234}, altText:{title:"rare-class threshold trade-off",description:"classification threshold trade-off and base-rate precision collapse",name:"threshold"} })] }));
      children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{after:160}, keepLines:true,
        children:[new TextRun({text:"Figure 9. The classification challenge for a rare condition, from the fused model's out-of-bag predictions on 4,168 true-coordinate plots. (a) Sensitivity, specificity, precision, and F1 as the probability threshold varies: raising the threshold to suppress false positives sacrifices sensitivity, and no single cutoff is optimal for every objective. The discrimination-optimal threshold (Youden's J) is 0.36, where precision is still only about 0.51. (b) Precision at that optimal operating point as a function of the true landscape prevalence, holding the model's skill fixed (AUC 0.87): precision falls from about 51 percent on the training set to about 40 percent at the any-LSOG prevalence, about 11 percent at the strict four-axis prevalence, and under 1 percent for the old-growth-only class. High overall discrimination does not translate into reliable per-hectare calls when the target is rare, which is why the amount is anchored to the design-based inventory and the rare old-growth class must be field-verified.", italics:true, size:18})] }));
    }
    // inject documented old-growth stands map after the §3.2 training/validation paragraph
    if (line.startsWith("The map was trained on 463 hectares")){
      children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{before:60,after:50},
        children:[new ImageRun({ type:"png", data:fs.readFileSync(`${FIG}/Fig_datamap_ogstands.png`),
          transformation:{width:452,height:452}, altText:{title:"documented old-growth stands",description:"study-area datasets with FIA LSOG plots and documented stands",name:"ogstands"} })] }));
      children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{after:160}, keepLines:true,
        children:[new TextRun({text:"Figure 4. Field datasets and documented old-growth across the Maine study area. FIA plots are shown by their v5.1 class: old-growth (OG) plots as red stars, late-successional (LS) as orange points, transitioning-LS in grey, and other forest as faint grey; the ecological reserve network is in teal and the Baxter State Park inventory is outlined in green, with county boundaries for reference. Open circles are the 68 stands recommended across seven forest types in the 1983 Critical Areas inventory (hemlock, red and white spruce, white and red pine, cedar, oak, and hardwood; 104 field-checked; Maine State Planning Office 1983); black diamonds are the fifteen stands confirmed as true old-growth on State land in 1986 (1,553 acres; Maine State Planning Office 1986). The FIA-classified LSOG plots are few and scattered, and the documented old-growth concentrates in the northern townships the LiDAR analysis maps, exactly where a map-based prioritization most needs independent ground data, while the inventory's organization by forest type underscores that the qualifying structure is type-specific, not universal.", italics:true, size:18})] }));
    }
    // inject 3-map figure after the cross-map paragraph (2.4)
    if (!injectedFig && line.startsWith("When three independent remote-sensing")){
      children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{before:60,after:50},
        children:[new ImageRun({ type:"png", data:fs.readFileSync(`${FIG}/Fig1_2x2_statewide.png`),
          transformation:{width:430,height:466}, altText:{title:"four maps 2x2",description:"statewide four-map comparison with county boundaries",name:"fourmaps"} })] }));
      children.push(new Paragraph({ alignment:AlignmentType.CENTER, spacing:{after:160}, keepLines:true,
        children:[new TextRun({text:"Figure 1. Four independent operationalizations of LSOG over Maine at 100 m, shown statewide with county boundaries: (a) the reproduced published airborne-LiDAR classifier (Hagan et al. 2026; any-LSOG 21.9% of forested area); (b) the Potapov/GEDI spaceborne canopy-height model, P(LSOG) (14.0%); (c) the TreeMap FIA-imputed LSOG class (2.9%); and (d) the number of maps agreeing on LSOG per cell (0 to 3). The maps disagree markedly in both amount and location. A continental old-growth product (ORNL national stratum, 36.1%) is compared in Table A5; across all products only a few percent of the flagged ground is agreed by every map. Each panel is clipped to the Maine land area.", italics:true, size:18})] }));
      injectedFig=true;
    }
    // inject stress-test table inside Robustness section
    if (!injectedStress && line.startsWith("We stress tested")){
      children.push(new Paragraph({ spacing:{before:60,after:50}, children:[new TextRun({text:"Stress test: does “Maine lowest” survive the analytical choices? (plot-level prevalence used for ordering)", bold:true, size:20})] }));
      children.push(table([
        ["Perturbation","Maine share [95% CI]","Maine lowest of 4?","Confidence"],
        ["Any-LSOG cutoff, looser (score ≥3)","40.9% [39.7-42.1]","Yes","High"],
        ["Any-LSOG cutoff, base (score ≥4)","24.8% [23.8-25.9]","Yes","High"],
        ["Any-LSOG cutoff, tighter (score ≥5)","12.9% [12.1-13.8]","Yes","High"],
        ["True-LSOG cutoff (score ≥7)","1.9% [1.6-2.3]","Yes","Medium"],
        ["True-LSOG cutoff (score ≥8)","0.4% [0.3-0.6]","Yes","Medium"],
        ["True-LSOG cutoff, extreme (score ≥9)","0.1% [0.1-0.3]","Tied lowest (all ~0.1%, noise)","Low"],
        ["Canopy dimension removed entirely","20.3%","Yes","High"],
        ["FIA panel 2014-2018","23.9%","Yes","High"],
        ["FIA panel 2019-2023","25.8%","Yes","High"],
      ], [3760,1900,2200,1500]));
      children.push(new Paragraph({ spacing:{after:160}, keepLines:true, children:[new TextRun({text:"Maine is the lowest-share state in 8 of 9 perturbations, and its Wilson 95% confidence interval lies entirely below the other three states at every cutoff except the most extreme, where every state collapses to about one-tenth of one percent and the intervals overlap. The ordering is therefore not a knife-edge result.", italics:true, size:18})] }));
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
      children:[new TextRun({text:"LSOG in Northern New England: A General Technical Assessment", size:14, color:"777777"})] })] }) },
    footers: { default: new Footer({ children:[new Paragraph({ alignment:AlignmentType.CENTER,
      children:[new TextRun({text:"Page ",size:16}), new TextRun({children:[PageNumber.CURRENT],size:16})] })] }) },
    children,
  }],
});
Packer.toBuffer(doc).then((b)=>{ fs.writeFileSync("/sessions/vibrant-lucid-faraday/mnt/outputs/CRSF_LSOG_Technical_Report.docx", b);
  console.log("wrote", b.length, "bytes"); });
