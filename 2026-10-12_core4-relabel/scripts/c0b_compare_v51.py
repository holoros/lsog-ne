#!/usr/bin/env python3
# c0b: aggregate crosstabs of CORE4 sample axes (Maine) against the v5.1 axes in tmp_me_v51_restricted.csv (key row_idx = k + 1).
import pandas as pd
s = pd.read_csv('/fs/scratch/PUOM0008/crsfaaron/core4_10m/menb-core4-10m_2026-09-16/inputs/samp_dat_core4_DATA_2026-09-02.csv')
s = s[s.jurisdiction == 'ME'].copy(); s['row_idx'] = s.plot_id.str[3:].astype(int) + 1
v = pd.read_csv('/fs/scratch/PUOM0008/crsfaaron/tmp_me_v51_restricted.csv').drop(columns=['TRUE.LAT', 'TRUE.LON', 'PLT_CN'])
x = s.merge(v, on='row_idx', suffixes=('', '_v51'))
print('matched', len(x), 'of', len(s))
for a in ['s_ba', 's_mat', 's_str', 's_can']:
    print(a); print(pd.crosstab(x[a], x[a + '_v51']).to_string())
print('total_score equal', (x.total_score == x.total_score_v51).mean(), 'total_score_old equal', (x.total_score == x.total_score_old).mean())
x['c4v'] = x.s_ba_v51 + x.s_mat_v51.clip(upper=1) + x.s_str_v51 + x.s_can_v51
print('core4 == sum v51 with s_mat capped at 1', (x.c4v == x.core4).mean(), ' cut3 agreement', ((x.c4v >= 3) == (x.core4 >= 3)).mean())
x['c4w'] = x.s_ba_v51 + x.s_mat_v51 + x.s_str_v51 + x.s_can_v51
print('core4 == sum v51 uncapped', (x.c4w == x.core4).mean(), ' cut3 agreement', ((x.c4w >= 3) == (x.core4 >= 3)).mean())
