const fs=require("fs");
const {Document,Packer,Paragraph,TextRun,Table,TableRow,TableCell,AlignmentType,HeadingLevel,BorderStyle,WidthType,ShadingType,ImageRun}=require("docx");
const GREEN="1A3D28",GREY="555555",CW=9360;
const bd={style:BorderStyle.SINGLE,size:1,color:"BBBBBB"},bds={top:bd,bottom:bd,left:bd,right:bd};
const H=(t,l)=>new Paragraph({heading:l,children:[new TextRun(t)]});
const P=(t)=>new Paragraph({spacing:{after:140,line:280},alignment:AlignmentType.JUSTIFIED,children:[new TextRun({text:t,size:21})]});
const cap=(t)=>new Paragraph({spacing:{before:50,after:200},children:[new TextRun({text:t,size:18,italics:true,color:GREY})]});
function rnd(s){const n=Number(s); if(!isFinite(n)||s===""||s===undefined) return s; return Math.abs(n)>=1000?Math.round(n).toLocaleString():(Math.round(n*1000)/1000).toString();}
function csvTable(path,sel,headerMap){
  const rows=fs.readFileSync(path,"utf8").trim().split(/\r?\n/).map(r=>r.split(","));
  let hdr=rows[0], idx=hdr.map((_,i)=>i);
  if(sel){ idx=sel.map(s=>hdr.indexOf(s)); hdr=sel; }
  const out=[[...hdr.map(h=>headerMap&&headerMap[h]?headerMap[h]:h)]];
  for(let i=1;i<rows.length;i++){ out.push(idx.map(j=>rnd(rows[i][j]))); }
  const w=Math.floor(CW/out[0].length); const widths=out[0].map(()=>w);
  return new Table({width:{size:CW,type:WidthType.DXA},columnWidths:widths,
    rows:out.map((r,ri)=>new TableRow({children:r.map(c=>new TableCell({borders:bds,width:{size:w,type:WidthType.DXA},
      shading:{fill:ri===0?GREEN:"FFFFFF",type:ShadingType.CLEAR},margins:{top:40,bottom:40,left:80,right:80},
      children:[new Paragraph({children:[new TextRun({text:String(c),bold:ri===0,color:ri===0?"FFFFFF":"000000",size:16})]})]}))}))});
}
const S="suppl/";
const k=[];
k.push(new Paragraph({spacing:{after:120},children:[new TextRun({text:"Supporting Information",bold:true,size:30,color:GREEN})]}));
k.push(new Paragraph({spacing:{after:240},children:[new TextRun({text:"for: Using LiDAR to quantify, map, and conserve late-successional and old-growth forest in Maine, USA: Comment (A. R. Weiskittel).",size:20,italics:true,color:GREY})]}));

k.push(H("Appendix S1. Methods",HeadingLevel.HEADING_1));
k.push(P("Reproduction. The published random forest was refit from the archived 463-plot training data (8 LiDAR canopy metrics) with mtry=2 and 500 trees, reproducing the binary out-of-bag accuracy (94.2% vs 94.1%) and the top predictor. The model was applied to the archived per-hectare LiDAR metrics for the full area of interest (4,282,675 ha) to reproduce the wall-to-wall classification, and a 20-seed ensemble bounded the area estimate and the cross-validation agreement (Table S3)."));
k.push(P("Cross-map comparison. Three wall-to-wall classifications were placed on a common 100 m grid: the reproduced Hagan classifier; a logistic model of the FIA field class on Potapov (GEDI-calibrated) canopy height (calibrated to the FIA plot prevalence); and the USFS TreeMap 2022 imputation of FIA structural class. Pairwise Cohen kappa and Jaccard, three-way concordance, and the overlap of top-priority protected sets were computed."));
k.push(P("Accuracy on the training plots. Cross-validated AUC (repeated stratified five-fold, 40 repeats) was estimated for three predictor sets (8 LiDAR metrics; canopy height only; ground structure) against three targets, under random forest and logistic regression (Table S1). The capacity of the LiDAR metrics to predict the ground structural attributes that define old growth was assessed by cross-validated R-squared (Table S6)."));
k.push(P("FIA design-based estimation. Design-based older-forest area and 2003-2024 trend were estimated with rFIA (post-stratified, with FIA estimation-unit areas) over all Maine inventory years, for stand-age and large-tree basal-area domains, statewide and in the northern timberland units. Sensitivity to the large-tree threshold is in Table S2."));
k.push(P("Hex-scale summary. Each method's any-LSOG was aggregated to 8 km hexagons (n = 984) over the area of interest; the cross-method disagreement (maximum minus minimum any-LSOG fraction per hexagon) had mean 0.22 and median 0.19 (Fig. S1)."));
k.push(P("Data and code. All scripts and derived products are archived at Zenodo (concept DOI 10.5281/zenodo.20614496). FIA data are from the USDA FIA DataMart; Hagan training data and code from Zenodo 10.5281/zenodo.19696494."));

k.push(H("Table S1. AUC by classifier and predictor set",HeadingLevel.HEADING_1));
k.push(csvTable(S+"S2_auc_classifier_robustness.csv"));
k.push(cap("Table S1. Cross-validated AUC (mean and 95% interval) by classifier (random forest, logistic regression), target, and predictor set. Canopy-height-only is weakest for old growth under both classifiers."));

k.push(H("Table S2. FIA design-based sensitivity to the large-tree threshold",HeadingLevel.HEADING_1));
k.push(csvTable(S+"S1_fiadb_threshold_sensitivity.csv",["domain","yr","pct","lo","hi","slope","slope_lo","slope_hi"],{pct:"2024 %",lo:"lo",hi:"hi",slope:"trend %/yr",slope_lo:"slope lo",slope_hi:"slope hi"}));
k.push(cap("Table S2. Design-based older-forest area (large-tree basal area domain) at three thresholds, with 95% CI and 2003-2024 trend. The increasing trend is robust to the threshold."));

k.push(H("Table S2b. FIA older forest by ownership (private commercial vs public)",HeadingLevel.HEADING_1));
k.push(csvTable(S+"S1_oldforest_by_ownership.csv",["domain","owner","pct","lo","hi","slope","slope_lo","slope_hi"],{pct:"2024 %",slope:"trend %/yr",slope_lo:"slope lo",slope_hi:"slope hi"}));
k.push(cap("Table S2b. Design-based older-forest area by ownership group with 95% CI and 2003-2024 trend. Older forest is rising on private commercial timberland as well as public land."));

k.push(H("Table S3. Random forest stochasticity (20-seed ensemble)",HeadingLevel.HEADING_1));
k.push(csvTable(S+"S1_multiseed_summary.csv"));
k.push(cap("Table S3. Mean, SD, and range across 20 random forest seeds for reproduced accuracy, wall-to-wall area, and cross-validation agreement."));

k.push(H("Table S4. Cross-method disagreement by owner class",HeadingLevel.HEADING_1));
k.push(csvTable(S+"T4_ownership_consensus.csv",["owner","any_flag_ha","consensus_ha","contested_ha","pct_contested_of_flagged"],{owner:"owner code",any_flag_ha:"flagged ha",consensus_ha:"all-agree ha",contested_ha:"contested ha",pct_contested_of_flagged:"% contested"}));
k.push(cap("Table S4. Of the LSOG flagged by any method, the share that is contested (flagged by one or two methods, not all) by owner class. Disagreement is pervasive across ownership."));

k.push(H("Table S5. TreeMap LSOG time series",HeadingLevel.HEADING_1));
k.push(csvTable(S+"T1_treemap_lsog_timeseries.csv",["year","any_LSOG_pct","LS_OG_pct","known_ha"],{any_LSOG_pct:"any-LSOG %",LS_OG_pct:"LS+OG %",known_ha:"known ha"}));
k.push(cap("Table S5. TreeMap-imputed LSOG area over 2016-2022 (native 30 m), Maine unorganized townships."));

k.push(H("Table S6. LiDAR prediction of structure, and old-growth discriminators",HeadingLevel.HEADING_1));
k.push(csvTable(S+"T2_lidar_predicts_structure_R2.csv",["structural_var","cv_R2_from_LiDAR","lo","hi"],{structural_var:"structural attribute",cv_R2_from_LiDAR:"CV R-squared from LiDAR"}));
k.push(cap("Table S6a. Cross-validated R-squared for predicting ground structural attributes from the eight LiDAR metrics. Dead wood (CWD, snags) is poorly predicted."));
k.push(csvTable(S+"T3_OG_variable_importance.csv",["variable","set","MeanDecreaseAccuracy"],{MeanDecreaseAccuracy:"importance (MDA)"}));
k.push(cap("Table S6b. Old-growth discriminators (random forest variable importance) across LiDAR and ground-structure variables."));

k.push(H("Figure S1. Hex-scale cross-map disagreement",HeadingLevel.HEADING_1));
k.push(new Paragraph({alignment:AlignmentType.CENTER,spacing:{before:80,after:40},children:[new ImageRun({type:"png",data:fs.readFileSync("figs/Fig_hex.png"),transformation:{width:468,height:143},altText:{title:"hex",description:"hex",name:"hex"}})]}));
k.push(cap("Figure S1. Any-LSOG fraction by method aggregated to 8 km hexagons over the area of interest, and the cross-method disagreement (max minus min). Disagreement concentrates in the northern and central townships."));

const doc=new Document({styles:{default:{document:{run:{font:"Times New Roman",size:21}}},
  paragraphStyles:[{id:"Heading1",name:"Heading 1",basedOn:"Normal",next:"Normal",quickFormat:true,run:{size:23,bold:true,color:GREEN,font:"Times New Roman"},paragraph:{spacing:{before:220,after:100}}}]},
  sections:[{properties:{page:{size:{width:12240,height:15840},margin:{top:1440,right:1080,bottom:1440,left:1080}}},children:k}]});
Packer.toBuffer(doc).then(b=>{fs.writeFileSync("Ecosphere_Comment_Hagan_SupportingInfo.docx",b);console.log("WROTE supplement");});
