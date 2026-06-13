const pptxgen = require("/sessions/vibrant-lucid-faraday/mnt/outputs/node_modules/pptxgenjs");
const D = "/sessions/vibrant-lucid-faraday/mnt/outputs";
const p = new pptxgen();
p.defineLayout({ name:"W", width:13.33, height:7.5 }); p.layout="W";

const GREEN="1A3D28", ACCENT="2E7D32", CHAR="333333", GRAY="666666", LGRAY="999999", BAND="1A3D28";
const TITLE_FONT="Aptos Display", BODY="Aptos";

function band(s, text){ // takeaway band
  s.addShape(p.ShapeType.rect,{x:0,y:6.85,w:13.33,h:0.65,fill:{color:BAND}});
  s.addText(text,{x:0.5,y:6.85,w:12.3,h:0.65,fontFace:BODY,fontSize:18,color:"FFFFFF",bold:true,valign:"middle"});
}
function title(s, t, sub){
  s.addText(t,{x:0.6,y:0.35,w:12.1,h:0.8,fontFace:TITLE_FONT,fontSize:30,color:CHAR,bold:true});
  if(sub) s.addText(sub,{x:0.6,y:1.12,w:12.1,h:0.5,fontFace:BODY,fontSize:16,color:GRAY,italic:true});
}
function cite(s, txt){ s.addText(txt,{x:0.6,y:6.35,w:12.1,h:0.4,fontFace:BODY,fontSize:10,color:LGRAY}); }

// ---- Slide 1: title ----
let s=p.addSlide(); s.background={color:"FFFFFF"};
try{ s.addImage({path:`${D}/crsf_logo.png`, x:0.6, y:0.5, w:2.6, h:0.95}); }catch(e){}
s.addText("Late-successional and old-growth forest across northern New England",
  {x:0.7,y:2.0,w:12.0,h:1.6,fontFace:TITLE_FONT,fontSize:40,color:GREEN,bold:true});
s.addText("What the inventory shows, and the limits of LiDAR-based mapping",
  {x:0.7,y:3.7,w:12.0,h:0.6,fontFace:BODY,fontSize:22,color:CHAR,italic:true});
s.addText("Briefing for the Maine Forest Products Council",
  {x:0.7,y:4.7,w:12.0,h:0.5,fontFace:BODY,fontSize:20,color:ACCENT,bold:true});
s.addText("Aaron R. Weiskittel and colleagues  |  Center for Research on Sustainable Forests, University of Maine  |  June 2026",
  {x:0.7,y:5.4,w:12.0,h:0.5,fontFace:BODY,fontSize:14,color:GRAY});

// ---- Slide 2: the question ----
s=p.addSlide(); s.background={color:"FFFFFF"}; title(s,"Why this briefing");
s.addText([
  {text:"A LiDAR map has put welcome attention on Maine's older forest, and a downstream report proposes spending on the order of $200 to $300 million to protect the highest-priority acres (LD 1529).",options:{bullet:true,fontSize:20,color:CHAR,paraSpaceAfter:10}},
  {text:"Before one map anchors spending at that scale, two things are needed: examine the map's fitness for the purpose, and reframe the question from one state to the region the forest belongs to.",options:{bullet:true,fontSize:20,color:CHAR,paraSpaceAfter:10}},
  {text:"This is not an argument against conserving older forest. It is an argument for honest numbers and the right map.",options:{bullet:true,fontSize:20,color:CHAR}},
],{x:0.7,y:1.7,w:11.9,h:4.5,fontFace:BODY,valign:"top"});
band(s,"Reframe from a single state and a single map to a regional, uncertainty-aware account");

// ---- Slide 3: five findings (cards) ----
s=p.addSlide(); s.background={color:"FFFFFF"}; title(s,"Five primary findings");
const cards=[
  ["How much LSOG?","A range with intervals, not a point: 3.9% [3.3 to 4.6] at age ≥120 yr; 14.1% [12.9 to 15.3] integrated."],
  ["Depends how you count","Same forest is ~3% LSOG (four axes) to over 90% (one axis)."],
  ["Regional ranking","Maine lowest share, the expected signature of its production role, not a deficit."],
  ["Is it disappearing?","Net stock stable to rising, 2003 to 2024. The cited loss is a gross harvest flux."],
  ["Do maps agree?","Independent credible maps differ 1.6 to 2.6 fold and agree on few percent of the ground."],
];
let cx=0.7, cw=2.42, gap=0.06;
cards.forEach((c,i)=>{ const x=cx+i*(cw+gap);
  s.addShape(p.ShapeType.rect,{x,y:1.8,w:cw,h:4.2,fill:{color:"F4F6F4"},line:{type:"none"}});
  s.addShape(p.ShapeType.rect,{x,y:1.8,w:0.08,h:4.2,fill:{color:ACCENT}});
  s.addText(c[0],{x:x+0.16,y:2.0,w:cw-0.3,h:0.9,fontFace:TITLE_FONT,fontSize:16,color:GREEN,bold:true,valign:"top"});
  s.addText(c[1],{x:x+0.16,y:2.95,w:cw-0.3,h:2.9,fontFace:BODY,fontSize:14,color:CHAR,valign:"top"});
});
band(s,"The headline percentage is a definitional and statistical choice, and should be reported as a range");

// ---- Slide 4: limitation 1 ----
s=p.addSlide(); s.background={color:"FFFFFF"}; title(s,"Limitation 1: 90% measures label agreement, not correctness");
s.addText([
  {text:"The reported accuracy is how often the model reproduces its own field labels, not whether the map is right against an independent standard.",options:{bullet:true,fontSize:20,color:CHAR,paraSpaceAfter:12}},
  {text:"On the project's own accounting, only ~29% of true old-growth plots were classified as old growth. The headline is carried by the common non-LSOG class.",options:{bullet:true,fontSize:20,color:CHAR,paraSpaceAfter:12}},
  {text:"A routine rebalancing of the same model nearly doubles the mapped old-growth area, so the single number should not be taken at face value.",options:{bullet:true,fontSize:20,color:CHAR}},
],{x:0.7,y:1.7,w:11.9,h:4.4,fontFace:BODY,valign:"top"});
band(s,"High label agreement does not mean the map selects the right acres");

// ---- Slide 5: limitation 2 dead wood ----
s=p.addSlide(); s.background={color:"FFFFFF"}; title(s,"Limitation 2: canopy LiDAR maps big-tree forest, not old growth");
s.addText([
  {text:"Canopy height predicts large trees moderately (R² ≈ 0.68) but is largely blind to dead wood (coarse woody debris R² ≈ 0.20, snags R² ≈ 0.24).",options:{bullet:true,fontSize:20,color:CHAR,paraSpaceAfter:12}},
  {text:"The blind spot reaches the field protocol too: in the RAP v2.0 classifier, large dead trees rank last of 17 metrics and large logs 13th, while harvest-history evidence is among the strongest predictors.",options:{bullet:true,fontSize:20,color:CHAR,paraSpaceAfter:12}},
  {text:"A global sensitivity analysis confirms it: canopy height drives nearly all of the modeled probability; the disturbance signal is secondary.",options:{bullet:true,fontSize:20,color:CHAR}},
],{x:0.7,y:1.7,w:11.9,h:4.4,fontFace:BODY,valign:"top"});
cite(s,"Dead-wood importance: Shamgochian, Hagan, Taylor & Reed (2025), RAP v2.0, Our Climate Common.");
band(s,"Tall, big-tree forest is roughly 3 to 4 times more extensive than ground-defined old forest");

// ---- Slide 6: limitation 3 maps disagree (figure) ----
s=p.addSlide(); s.background={color:"FFFFFF"}; title(s,"Limitation 3: independent credible maps disagree");
s.addImage({path:`${D}/msComment_ensemble.png`, x:1.2, y:1.55, w:10.9, h:4.6});
band(s,"Maps differ 1.6 to 2.6 fold in amount; only ~3% of flagged acres are agreed by all three");

// ---- Slide 7: design-based range (metrics) ----
s=p.addSlide(); s.background={color:"FFFFFF"}; title(s,"Our finding: how much, with the interval the map omits");
const mets=[["3.9%","older forest, age ≥120 yr","[3.3 to 4.6]"],["14.1%","integrated structural proxy","[12.9 to 15.3]"],["3.1%","true LSOG, all four axes","[2.5 to 3.7]"]];
mets.forEach((m,i)=>{ const x=1.3+i*3.9;
  s.addText(m[0],{x,y:2.4,w:3.4,h:1.0,fontFace:TITLE_FONT,fontSize:54,color:GREEN,bold:true,align:"center"});
  s.addText(m[1],{x,y:3.5,w:3.4,h:0.6,fontFace:BODY,fontSize:16,color:CHAR,align:"center"});
  s.addText(m[2],{x,y:4.0,w:3.4,h:0.5,fontFace:BODY,fontSize:15,color:GRAY,align:"center"});
});
s.addText("Design-based estimates from the FIA probability sample, Maine forestland. The federal threat analysis could not resolve eastern old growth nationally because FIA plots are too sparse, which is exactly why a region-targeted estimate with its interval is the right tool.",
  {x:1.0,y:5.0,w:11.3,h:1.5,fontFace:BODY,fontSize:15,color:CHAR,align:"center"});
band(s,"The honest unit is the design-based estimate with its confidence interval");

// ---- Slide 8: funnel ----
s=p.addSlide(); s.background={color:"FFFFFF"}; title(s,"It depends how you count");
s.addText([
  {text:"Requiring one axis: over 90% of forest qualifies.",options:{bullet:true,fontSize:22,color:CHAR,paraSpaceAfter:14}},
  {text:"Requiring all four axes (live structure, dead wood, composition, continuity): about 3% in Maine, 12 to 15% in New Hampshire, Vermont, and New York.",options:{bullet:true,fontSize:22,color:CHAR,paraSpaceAfter:14}},
  {text:"The same forest is anywhere from 3% to over 90% LSOG. The number is a choice about how many criteria to require.",options:{bullet:true,fontSize:22,color:CHAR,bold:true}},
],{x:0.7,y:1.8,w:11.9,h:4.2,fontFace:BODY,valign:"top"});
band(s,"Report the curve, not a single percentage");

// ---- Slide 9: regional triad ----
s=p.addSlide(); s.background={color:"FFFFFF"}; title(s,"New England functions as a working-forest triad");
s.addText([
  {text:"Maine's heavily worked timberland anchors the production tier; New Hampshire and Vermont's aging old-field forests and New York's Adirondack reserves carry more of the late-successional and reserve tiers.",options:{bullet:true,fontSize:20,color:CHAR,paraSpaceAfter:12}},
  {text:"Maine's low share is the expected signature of its role, not a deficit to be closed within the state.",options:{bullet:true,fontSize:20,color:CHAR,paraSpaceAfter:12}},
  {text:"The right question is regional representation across forest types and ecoregions. True LSOG occurs in 7 of 8 forest types but concentrates in northern hardwood and pine and is thin in spruce-fir.",options:{bullet:true,fontSize:20,color:CHAR}},
],{x:0.7,y:1.7,w:11.9,h:4.4,fontFace:BODY,valign:"top"});
band(s,"Target under-represented types and ecoregions, not per-state parity");

// ---- Slide 10: flux vs stock ----
s=p.addSlide(); s.background={color:"FFFFFF"}; title(s,"The stock is stable to rising, not collapsing");
s.addText([
  {text:"Individual mapped stands are harvested, at roughly 2% per year of mapped LSOG. That flux is real.",options:{bullet:true,fontSize:21,color:CHAR,paraSpaceAfter:14}},
  {text:"But the net older-forest stock increased across the operational age and structure measures over 2003 to 2024, while total forestland stayed flat, because younger stands age into the older condition faster than older stands are cut.",options:{bullet:true,fontSize:21,color:CHAR,paraSpaceAfter:14}},
  {text:"A gross flux and a net stock point in opposite directions and should not be conflated.",options:{bullet:true,fontSize:21,color:CHAR,bold:true}},
],{x:0.7,y:1.8,w:11.9,h:4.2,fontFace:BODY,valign:"top"});
band(s,"Distinguish the harvest flux from the net stock trend wherever loss is invoked");

// ---- Slide 11: ensemble uncertainty (figure) ----
s=p.addSlide(); s.background={color:"FFFFFF"}; title(s,"A probabilistic map with quantified uncertainty");
s.addImage({path:`${D}/msFig_ensemble_uncertainty.png`, x:1.6, y:1.5, w:10.1, h:4.6});
band(s,"Five models span 0.26 to 0.59 mean probability; map the disagreement, do not hide it");

// ---- Slide 12: stress test ----
s=p.addSlide(); s.background={color:"FFFFFF"}; title(s,"The conclusions are robust");
s.addText([
  {text:"\"Maine lowest\" holds in 8 of 9 stress tests: every reasonable scoring threshold, with the canopy dimension removed entirely, and across both FIA measurement panels.",options:{bullet:true,fontSize:21,color:CHAR,paraSpaceAfter:14}},
  {text:"The rarity of true LSOG holds across five ways of drawing the continuity axis. The cross-map disagreement is not an artifact of any one product.",options:{bullet:true,fontSize:21,color:CHAR,paraSpaceAfter:14}},
  {text:"These are stable features of the data, not knife-edge results that depend on one threshold.",options:{bullet:true,fontSize:21,color:CHAR,bold:true}},
],{x:0.7,y:1.8,w:11.9,h:4.2,fontFace:BODY,valign:"top"});
band(s,"Headline findings survive the analytical choices most likely to be questioned");

// ---- Slide 13: recommendations ----
s=p.addSlide(); s.background={color:"FFFFFF"}; title(s,"Recommendations");
const recs=[
  ["Report a range","LSOG extent as a method range with design-based intervals, not a single percentage."],
  ["Use the stable unit","Treat late-successional plus old-growth as the policy class; old-growth alone is product-specific."],
  ["Cross-check and verify","Check any single map against an independent product and field-verify before acquisition."],
  ["Frame regionally","Pursue representation across northern New England, not per-state parity."],
];
recs.forEach((c,i)=>{ const x=0.7+(i%2)*6.1, y=1.8+Math.floor(i/2)*2.25;
  s.addShape(p.ShapeType.rect,{x,y,w:5.9,h:2.05,fill:{color:"F4F6F4"}});
  s.addShape(p.ShapeType.rect,{x,y,w:0.08,h:2.05,fill:{color:ACCENT}});
  s.addText(c[0],{x:x+0.2,y:y+0.15,w:5.5,h:0.5,fontFace:TITLE_FONT,fontSize:18,color:GREEN,bold:true});
  s.addText(c[1],{x:x+0.2,y:y+0.75,w:5.5,h:1.2,fontFace:BODY,fontSize:16,color:CHAR,valign:"top"});
});
band(s,"Honest numbers and the right map, in service of a working forest");

// ---- Slide 14: closing ----
s=p.addSlide(); s.background={color:"FFFFFF"};
try{ s.addImage({path:`${D}/crsf_logo.png`, x:5.1, y:1.6, w:3.1, h:1.15}); }catch(e){}
s.addText("Questions and discussion",{x:1,y:3.2,w:11.3,h:1.0,fontFace:TITLE_FONT,fontSize:46,color:GREEN,bold:true,align:"center"});
s.addShape(p.ShapeType.rect,{x:0,y:6.5,w:13.33,h:1.0,fill:{color:BAND}});
s.addText("Aaron R. Weiskittel  |  aaron.weiskittel@maine.edu  |  Center for Research on Sustainable Forests, University of Maine",
  {x:0.5,y:6.5,w:12.3,h:1.0,fontFace:BODY,fontSize:16,color:"FFFFFF",align:"center",valign:"middle"});

p.writeFile({ fileName:`${D}/MFPC_LSOG_Briefing.pptx` }).then(()=>console.log("deck written"));
