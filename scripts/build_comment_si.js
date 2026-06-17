const fs = require("fs");
const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
        AlignmentType, BorderStyle, WidthType, ShadingType, LineNumberRestartFormat } = require("docx");

function S(t){ t = String(t)
  .replace(/ft\^2/g,"ft²").replace(/m\^3/g,"m³").replace(/R\^2/g,"R²")
  .replace(/>=/g,"≥").replace(/<=/g,"≤"); t = t.split(/(\s+)/).map(function(w){return /https?:\/\/|doi\.org/.test(w)?w:w.replace(/(\d)-(\d)/g,"$1–$2");}).join(""); return t; }
function P(text){ return new Paragraph({ spacing:{line:480,after:0}, children:[new TextRun({text:S(text),size:24})] }); }
function H(text){ return new Paragraph({ spacing:{line:480,before:240,after:60}, children:[new TextRun({text,bold:true,size:24})] }); }
function blank(){ return new Paragraph({spacing:{line:240},children:[new TextRun("")]}); }
const border={style:BorderStyle.SINGLE,size:1,color:"999999"}; const borders={top:border,bottom:border,left:border,right:border};
function tcell(text,w,head){ return new TableCell({borders,width:{size:w,type:WidthType.DXA},
  shading:head?{fill:"D9E2EC",type:ShadingType.CLEAR}:undefined, margins:{top:40,bottom:40,left:100,right:100},
  children:[new Paragraph({spacing:{line:240},children:[new TextRun({text:S(text),bold:!!head,size:20})]})]}); }
function tableFrom(matrix,widths){ const total=widths.reduce((a,b)=>a+b,0);
  return new Table({width:{size:total,type:WidthType.DXA},columnWidths:widths,
    rows:matrix.map((row,ri)=>new TableRow({children:row.map((cell,ci)=>tcell(String(cell),widths[ci],ri===0))}))}); }

const c=[];
c.push(new Paragraph({spacing:{line:360,after:60},children:[new TextRun({text:"Supporting Information",bold:true,size:30})]}));
c.push(new Paragraph({spacing:{line:300,after:60},children:[new TextRun({text:"Using LiDAR to quantify, map, and conserve late-successional and old-growth forest in Maine, USA: Comment",italics:true,size:24})]}));
c.push(new Paragraph({spacing:{line:300,after:160},children:[new TextRun({text:"Aaron R. Weiskittel, University of Maine, Center for Research on Sustainable Forests",size:22})]}));

c.push(H("S1. Reproduction of the published classifier"));
c.push(P("We reproduced the random forest of Hagan et al. (2026) from their archived training data and code. On the 463 known-class training hectares with the eight LiDAR canopy metrics, the out-of-bag accuracy for the Not-LSOG versus LSOG distinction is 94.2%, against the 94.1% reported, with the same most-important predictor, canopy cover above 15 m. Applying the reproduced classifier to the public hectare-level LiDAR canopy statistics for all 4.28 million hectares of the study area reproduces the reported any-LSOG extent to within about two percentage points (22.0% against 19.7%); the residual reflects default classifier settings and grid alignment rather than the authors' exact configuration, while the model, the predictors, and the training labels are theirs. We separately reproduced the privately held Seven Islands classification and found it effectively identical to the published model (pixel-level kappa 0.97 across approximately 290,000 ha)."));

c.push(H("S2. Class rebalancing and the rare old-growth class"));
c.push(P("The mapped old-growth area is sensitive to a routine handling of class imbalance. Refitting the published classifier on the archived data under four standard treatments moves both old-growth detection and mapped area substantially (Table S1). Under balanced sub-sampling the any-LSOG share rises from 21.9% to 32.3% of forested hectares on the comparison grid. We do not claim the rebalanced classifier is the more correct one: class balancing trades omission of the rare class for commission, and which way the truth lies cannot be settled from the training labels alone. The point is that the headline area is unstable to a routine modeling choice that only independent field validation of the old-growth class could adjudicate."));
c.push(P("Table S1. Rare-class remedies for the reproduced airborne-LiDAR random forest, with old-growth as the rare event. Old-growth operating accuracy (recall) and the wall-to-wall mapped old-growth area both move sharply.",{}));
c.push(tableFrom([
  ["Strategy","Old-growth recall","Mapped old-growth area (% of forested area)"],
  ["Default, unbalanced","0.24","1.0"],
  ["Class weighting","0.29","0.8"],
  ["Balanced sub-sampling","0.71","1.9"],
  ["Voting-threshold adjustment","0.82","2.3"]],[3360,2400,3600]));
c.push(blank());

c.push(H("S3. Matched-prevalence cross-map comparison"));
c.push(P("To separate locational disagreement from any difference in amount, we thresholded our FIA-anchored 10 m embedding surface to flag the identical landscape fraction as the reproduced classifier (about 21.5% any-LSOG). At matched amount the two agree on only 7.7% of the landscape, each flagging roughly 14% the other does not, for a Cohen's kappa of 0.19. The same comparison on Seven Islands Land Company timberland against the company's own operational map gives kappa 0.24. Neither map is ground truth and neither is held up as correct; the comparison isolates and bounds the locational uncertainty that persists when two independent methods are forced to agree on the amount, and it is a lower bound, since a third credible method would only add disagreement."));

c.push(H("S4. Data and code availability"));
c.push(P("All code and derived products supporting this Comment, including the classifier reproduction, the rebalancing test, the matched-prevalence cross-map comparison, and the design-based FIA estimation, are archived at Zenodo (concept DOI 10.5281/zenodo.20614496, resolving to the latest version). Hagan et al.'s training data and code are at Zenodo (10.5281/zenodo.19696494). FIA data are from the USDA FIA DataMart (apps.fs.usda.gov/fia/datamart), accessed June 2026. FIA plot coordinates are restricted and are not released; only derived rasters and aggregate tables are archived."));

const doc=new Document({
  styles:{default:{document:{run:{font:"Times New Roman",size:24}}}},
  sections:[{properties:{page:{size:{width:12240,height:15840},
    margin:{top:1440,right:1440,bottom:1440,left:1440},
    lineNumbers:{countBy:1,restart:LineNumberRestartFormat.CONTINUOUS,distance:360}}},children:c}]});
Packer.toBuffer(doc).then(b=>{fs.writeFileSync("/sessions/vibrant-lucid-faraday/mnt/outputs/Ecosphere_Comment_Hagan_SI.docx",b);console.log("wrote comment SI",b.length);});
