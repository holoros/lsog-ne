# CORE4 relabel to the 2019 to 2023 remeasurement: stopped at the gate

October 12, 2026. Scripts in scripts/ (c0b, c0c, c0d), logs in logs/. Aggregates only; nothing plot level is written here.

## Scorer

The Maine CORE4 cut-3 label in core4_training_table_DATA_2026-09-25.csv comes from the s1 build (logs/s1_gates.txt of menb-core4-10m_2026-09-16), which adopted candidate C_point_sum: core4 = s_ba + s_mat + s_str + s_can, positive at core4 >= 3. The Maine axis scores in samp_dat_core4_DATA_2026-09-02.csv are identical, axis by axis for all 3,062 Maine rows, to the four axes in tmp_me_v51_restricted.csv, which mosvr_pipeline_run/step1_me_v51_score.R builds from output_unified/lsog_ne_plot_table.csv with these rules: s_ba 2 if ba_large >= 80 ft2/ac, 1 if >= 40; s_mat 1 if max_dia >= 24 in (no stand age term); s_str 2 if sd_dia >= 8 in, 1 if >= 5; s_can 2 if ba_total >= 150 ft2/ac, 1 if >= 100. Recomputing these from the plot table reproduces all four axes and the cut-3 label for 100 percent of rows (3,015 of 3,015 training rows; 3,062 of 3,062 sample rows).

## Why the gate cannot be run as specified

The plot table holds only the 2014 to 2018 and 2019 to 2023 Maine evaluations; the 2004 to 2008 CNs are not in it. step1 takes the latest plot-table visit at each STATECD, UNITCD, COUNTYCD, PLOT location and attaches the PLT_CN from FIA.xy.csv, which is the 2004 to 2008 visit. The PLT_CN in the training key is therefore the 2004 to 2008 CN, but the attributes, and so the label, come from the latest visit: for the 3,015 training rows, 2,970 were scored on a 2019 to 2023 visit and 45 on a 2014 to 2018 visit. No row was scored on 2004 to 2008. The label cannot be reproduced from the 2004 to 2008 CN with this scorer because the inputs for that visit do not exist in the table it reads, and the labels were never computed from that visit.

## What relabelling would change

Walking PREV_PLT_CN to the 2019 to 2023 descendant gives the same visit the label already uses for 2,969 plots, and the same mapping as r0's desc_map_RESTRICTED.csv. Scoring those descendants changes no label: 2,838 stay negative, 131 stay positive, none switch. The other 46 plots (3 positive) have no scored 2019 to 2023 descendant and would drop out. Unweighted rates are 4.44 percent on all 3,015, and 4.41 percent before and after on the 2,969 scored. A c18 refit would differ from s18 only by dropping those 46 plots, so it was not run.

## Bearing on the ordinal relabel

The ordinal training table that r0 relabelled (me_transitioning_training_table_DATA_2026-09-23.csv) is built from the same step1 rows, so it was also already scored on 2019 to 2023 visits (3,013 of 3,062) and 2014 to 2018 visits (49). The class changes r0 reported come from scoring with a different rubric (stand age maturity term, plot-specific snag thresholds, plot-table Potapov heights), not from a change of visit.
