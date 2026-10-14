#!/usr/bin/env python3
# c0c: replicate step1_me_v51_score.R row construction (without the Potapov re-extraction, which does not touch the CORE4 axes)
# and check which FIA visit the CORE4 axes were actually computed on. Aggregates only.
import pandas as pd, numpy as np
B = '/users/PUOM0008/crsfaaron/LSOG'; K = ['STATECD', 'UNITCD', 'COUNTYCD', 'PLOT']
u = pd.read_csv(f'{B}/output_unified/lsog_ne_plot_table.csv', dtype={'CN': str}, low_memory=False); me = u[u.state == 'ME'].copy()
plt = pd.read_csv('/fs/scratch/PUOM0008/crsfaaron/FIA/ME_PLOT.csv', dtype={'CN': str, 'PREV_PLT_CN': str}, usecols=['CN', 'PREV_PLT_CN', 'INVYR', 'MEASYEAR'] + K)
me = me.merge(plt[['CN'] + K].drop_duplicates(), on='CN')
me = me.sort_values(K + ['INVYR'], kind='mergesort').groupby(K, sort=True).tail(1)
xy = pd.read_csv(f'{B}/data/validation_restricted/FIA.xy.csv', dtype={'PLT_CN': str})
xy1 = xy[K + ['TRUE.LAT', 'TRUE.LON', 'PLT_CN']].drop_duplicates(subset=K, keep='first')
me = me.merge(xy1, on=K).sort_values(K, kind='mergesort')
me = me[me.ba_total.notna() & me.ba_large.notna() & me.sd_dia.notna() & me.max_dia.notna() & me.snag_tpa.notna() & me.potapov_rh95.notna()
        & np.isfinite(me['TRUE.LAT']) & np.isfinite(me['TRUE.LON'])].reset_index(drop=True)
me['row_idx'] = np.arange(1, len(me) + 1)
print('replicated rows', len(me))
me['a_ba'] = np.where(me.ba_large >= 80, 2, np.where(me.ba_large >= 40, 1, 0)); me['a_mat'] = (me.max_dia >= 24).astype(int)
me['a_str'] = np.where(me.sd_dia >= 8, 2, np.where(me.sd_dia >= 5, 1, 0)); me['a_can'] = np.where(me.ba_total >= 150, 2, np.where(me.ba_total >= 100, 1, 0))
t = pd.read_csv('/fs/scratch/PUOM0008/crsfaaron/tmp_me_v51_restricted.csv', dtype={'PLT_CN': str}).drop(columns=['TRUE.LAT', 'TRUE.LON'])
x = t.merge(me[['row_idx', 'PLT_CN', 'CN', 'INVYR', 'a_ba', 'a_mat', 'a_str', 'a_can']], on='row_idx', how='left', suffixes=('', '_rep'))
print('tmp rows', len(t), 'matched by row_idx', int(x.CN.notna().sum()), 'PLT_CN identical', int((x.PLT_CN == x.PLT_CN_rep).sum()))
for a in ['ba', 'mat', 'str', 'can']: print(a, 'axis agreement', round(float((x['s_' + a] == x['a_' + a]).mean()), 4))
print('INVYR of the plot-table visit the axes came from:', x.INVYR.value_counts().sort_index().to_dict())
print('attribute CN == label PLT_CN (the 2004-2008 key):', int((x.CN == x.PLT_CN).sum()))
pinv = dict(zip(plt.CN, plt.INVYR)); print('INVYR of label PLT_CN:', pd.Series([pinv.get(c) for c in x.PLT_CN]).value_counts().sort_index().to_dict())
# CORE4 sample agreement through this route
s = pd.read_csv('/fs/scratch/PUOM0008/crsfaaron/core4_10m/menb-core4-10m_2026-09-16/inputs/samp_dat_core4_DATA_2026-09-02.csv')
s = s[s.jurisdiction == 'ME'].copy(); s['row_idx'] = s.plot_id.str[3:].astype(int) + 1
y = s.merge(x[['row_idx', 'a_ba', 'a_mat', 'a_str', 'a_can', 'INVYR']], on='row_idx', how='left')
y['c4'] = y.a_ba + y.a_mat + y.a_str + y.a_can
print('CORE4 sample: point sum agreement', round(float((y.c4 == y.core4).mean()), 4), 'cut3 agreement', round(float(((y.c4 >= 3) == (y.core4 >= 3)).mean()), 4))
print('CORE4 sample visit INVYR', y.INVYR.value_counts().sort_index().to_dict())
