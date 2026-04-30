# LSOG Northeast Manuscript Draft V1: Introduction

**Working title:** Late Successional and Old Growth forest distribution across the Northeast: a four state comparison
**Target journal:** Ecological Applications (preferred); alternates Forest Ecology and Management or Conservation Biology
**Authors (working):** Aaron Weiskittel (UMaine, lead); Adam Daigneault (UMaine); Daniel Hayes (UMaine); plus possibly Thompson team and Phase 4/5 analytical team TBD
**Status:** V1 draft of Introduction, April 27, 2026
**Companion:** MANUSCRIPT_OUTLINE.md, NEXT_STEPS.md

---

## Abstract draft (250 words target)

Late successional and old growth (LSOG) forests provide habitat for species requiring structural complexity, store carbon at higher per area densities than younger forests, and represent particular conservation value in heavily managed landscapes. Across the Northeastern United States, four states (Maine, New Hampshire, New York, Vermont) share similar climatic conditions but differ markedly in forest history, ranging from continuous industrial forestry in Maine to broad land abandonment in New Hampshire and Vermont. We applied the RAP v2.0 LSOG classification protocol to FIA remeasurement plots in the four state region for the 2019 to 2023 panel and the 1999 to 2003 panel, totaling 6,646 plots in the recent panel. Results show that Maine has the lowest combined LSOG share at 25.8 percent, compared to New Hampshire at 55.6 percent, Vermont at 57.8 percent, and New York at 46.5 percent (the latter with the highest old growth class share at 2.5 percent reflecting the Adirondacks). Twenty year trend analysis shows New Hampshire and Vermont essentially doubled their LSOG share over the period (gains of 21.4 and 14.5 percentage points respectively), while Maine added only 3.6 points. Sensitivity analysis indicates that v5 RAP thresholds at 18 and 25 meters Potapov RH95 canopy height are conservative; 10 and 20 meter thresholds or continuous RH95 in logistic regression yield higher AUC against ORNL mature classification. The structural divergence has direct consequences for biodiversity, carbon storage, and forest policy across the four states. Maine's working forest economy is consistent with its lower LSOG share, but the management trade offs deserve explicit policy attention.

**Keywords:** Late successional and old growth, FIA, Northeast, working forest, RAP classification, forest aging

---

## 1. Introduction

### 1.1 Late successional and old growth forest as a conservation concern

Forests with mature and structurally complex stands provide ecosystem services that younger forests cannot. Cavity nesting birds depend on standing dead trees that take decades to develop. Many lichen species require old, structurally complex canopies. Some terrestrial salamanders prefer the deep coarse woody debris that accumulates in old forests over generations. Beyond habitat, structurally complex older forests typically store more carbon per acre than younger, simpler ones, and they store that carbon more durably across the time horizons relevant to climate adaptation planning.

The terminology and classification of these forests varies. We use "late successional and old growth" or LSOG as an umbrella term following the RAP v2.0 classification protocol developed for use with FIA inventory data. The classification distinguishes transitional late successional, late successional, and old growth classes based on multiple structural attributes including tree size, basal area, dead wood, and structural complexity. The protocol has been applied across multiple regions in the United States and provides a consistent comparative framework for systematic state and regional analyses.

Federal and state forest policy increasingly emphasizes LSOG protection. The USDA Forest Service has issued direction to consider old growth in forest planning. State ecological reserve programs have established networks of designated reserves for LSOG protection. Carbon market frameworks increasingly recognize the carbon value of older forests. These policy developments increase the value of accurate, comparative LSOG distribution data.

### 1.2 Northeastern forest history shapes current LSOG distribution

The Northeastern United States is one of the most heavily forested regions in the country. Maine alone accounts for approximately 89 percent forest cover, the highest of any state in the United States. New Hampshire, Vermont, and New York are also heavily forested, although with somewhat different histories than Maine.

Forest history across the four states diverges meaningfully. New Hampshire and Vermont saw their peak agricultural clearing in the 1800s, followed by widespread land abandonment as farms moved west. The forests that grew back after that abandonment, often called old field forests, reach ages of 100 to 150 years today. They are no longer young, and they are increasingly structurally complex.

New York followed a similar arc but with significant Adirondacks forest that retained more old growth conditions through the post Civil War era due to large state and private holdings that limited clearing. The Adirondacks remain the regional hotspot for old growth forest in the Northeastern United States.

Maine's forest history followed a different arc. The state has supported a continuous, large scale industrial forestry sector dating from the 1800s through today. Maine produces more pulpwood than any state east of the Mississippi River. The forests that supply that industry have been worked for generations. Active, productive, and economically essential, but with rotations long enough to grow merchantable trees and not long enough to produce the structural conditions associated with old growth forests.

These divergent histories produce different current forest age structures, even though all four states share similar climatic conditions and similar overall forest cover. A consistent comparative analysis of LSOG distribution across the four states is therefore informative for understanding how forest history shapes current ecological and policy conditions.

### 1.3 The RAP v2.0 classification framework

We use the RAP v2.0 classification protocol to identify and characterize LSOG forest plots in the FIA inventory. RAP v2.0 evaluates each plot across six structural dimensions including tree size attributes, basal area distribution, dead wood characteristics (standing snags and down dead wood), and structural complexity. Each dimension produces a score; aggregate scores classify plots into transitional late successional, late successional, or old growth categories.

Classifier variants used in this study include v4 (without remote sensing integration), v5 (with Potapov RH95 canopy height integrated using default 18 and 25 meter thresholds), v5b (alternative classifier variant for sensitivity analysis), and v5c (continuous RH95 in logistic regression for highest AUC against external validation). The v4 classifier supports historical comparison across panels (1999 to 2003 vs 2019 to 2023) where remote sensing canopy height was less consistently available. The v5 classifier reflects current best practice with remote sensing integration.

A bug in the dead wood scoring dimension was identified and fixed during the analysis on March 19, 2026. The original implementation incorrectly pulled snag counts from outside plot boundaries in some cases; the corrected version pulls snag counts from inside plot boundaries only, consistent with the RAP v2.0 protocol intent. All results reported here use the corrected classifier.

### 1.4 Research questions

This study addresses five research questions:

First, what is the share of LSOG forest in each Northeast state at the most recent FIA panel (2019 to 2023)?

Second, how does the share differ among states, and what historical processes account for the differences?

Third, what has been the 20 year trajectory of LSOG share in each state from 1999 to 2003 to 2019 to 2023?

Fourth, how sensitive are the classification results to threshold choices, particularly remote sensing canopy height integration?

Fifth, what are the implications for biodiversity, forest carbon, and forest policy across the four states?

### 1.5 Contribution

This study makes four contributions. First, it provides the first systematic four state comparison of LSOG distribution across the Northeast using a consistent FIA based methodology. Second, it documents the v4 versus v5 classifier variant comparison and characterizes the value added by remote sensing canopy height integration. Third, it presents 20 year trend analysis across the four states using the v4 classifier. Fourth, it conducts an RH95 threshold sensitivity analysis that informs methodological best practice for future LSOG classification work.

The findings inform forest policy across the four states, conservation prioritization within the regional ecological reserve system, climate adaptation planning, and the broader question of how working forest history shapes current and future forest age structure.

---

## Notes for next session

This V1 draft covers the Abstract and the Introduction (sections 1.1 through 1.5). Sections 2 through 5 (Methods, Results, Discussion, Conclusion) are still needed. The manuscript outline at MANUSCRIPT_OUTLINE.md has the structure; the regional results files in this folder have the data.

Open items for V2:

1. Aaron's review of the V1 Introduction for voice, accuracy, and emphasis
2. Coauthor input on framing (Adam Daigneault, Dan Hayes, possibly Thompson team)
3. Specific citations to compile (RAP v2.0 protocol papers, Potapov canopy height paper, FIA methodology references, Northeast forest history references)
4. Confirm exact statistics (4 states, 6,646 plots, etc.) against the unified plot table
5. Confirm Adirondacks framing matches NY DEC and TNC understanding
6. Draft sections 2 (Methods), 3 (Results), 4 (Discussion), 5 (Conclusion)

The V1 Introduction is approximately 1,200 words. The voice follows Aaron's conventions (no decorative hyphens or em dashes; concise; technical; active voice).

The Conversation article V2 already exists at `~/Documents/Claude/CRSF-Cowork/active-projects/crsf-strategic-plan/conversation_article_draft_v2.md` using the same finding for a general audience. The peer reviewed manuscript here is the source citation for the Conversation article when it submits.

---

*Draft path: `~/Documents/MAINE/DATA/FIA/ME/LSOG_cardinal_setup/MANUSCRIPT_DRAFT_V1_INTRODUCTION.md`*
*Outline reference: `~/Documents/MAINE/DATA/FIA/ME/LSOG_cardinal_setup/MANUSCRIPT_OUTLINE.md`*
*Source data: `~/Documents/MAINE/DATA/FIA/ME/LSOG_cardinal_setup/output_unified/lsog_ne_plot_table.csv`*
