#!/usr/bin/env python3
# c0d: does the visit the CORE4 axes were computed on equal the PREV_PLT_CN 2019-2023 descendant used by r0 (CN_2023)?
# And what would scoring CN_2023 with the CORE4 scorer change? Also: was the ordinal training table (r0's T0) on the same visits? Aggregates only.
import pandas as pd, numpy as np
B = '/users/PUOM0008/crsfaaron/LSOG'; K = ['STATECD', 'UNITCD', 'COUNTYCD', 'PLOT']
u = pd.read_csv(f'{B}/output_unified/lsog_ne_plot_table.csv', dtype={'CN': str}, low_memory=False); me = u[u.state == 'ME'].copy()
plt = pd.read_csv('/fs/scratch/PUOM0008/crsfaaron/FIA/ME_PLOT.csv', dtype={'CN': str, 'PREV_PLT_CN': str}, usecols=['CN', 'PREV_PLT_CN', 'INVYR'] + K)
me = me.merge(plt[['CN'] + K].drop_duplicates(), on='CN').sort_values(K + ['INVYR'], kind='mergesort').groupby(K, sort=True).tail(1)
xy = pd.read_csv(f'{B}/data/validation_restricted/FIA.xy.csv', dtype={'PLT_CN': str})
me = me.merge(xy[K + ['TRUE.LAT', 'TRUE.LON', 'PLT_CN']].drop_duplicates(subset=K, keep='first'), on=K).sort_values(K, kind='mergesort')
me = me[me.ba_total.notna() & me.ba_large.notna() & me.sd_dia.notna() & me.max_dia.notna() & me.snag_tpa.notna() & me.potapov_rh95.notna()
        & np.isfinite(me['TRUE.LAT']) & np.isfinite(me['TRUE.LON'])].reset_index(drop=True)
me['plot_id'] = ['ME_%05d' % i for i in range(len(me))]; me = me.rename(columns={'CN': 'CN_label_visit', 'INVYR': 'INVYR_label_visit'})
def score(d):
    a = np.where(d.ba_large >= 80, 2, np.where(d.ba_large >= 40, 1, 0)) + (d.max_dia >= 24).astype(int) \
        + np.where(d.sd_dia >= 8, 2, np.where(d.sd_dia >= 5, 1, 0)) + np.where(d.ba_total >= 150, 2, np.where(d.ba_total >= 100, 1, 0))
    return np.where(d.ba_large.notna() & d.max_dia.notna() & d.sd_dia.notna() & d.ba_total.notna(), a, np.nan)
c4 = pd.read_csv('/fs/scratch/PUOM0008/crsfaaron/core4_10m/nb-core4-licensed-tsd2024-10m_2026-10-05/core4_training_table_DATA_2026-09-25.csv', usecols=['plot_id_export', 'jurisdiction', 'core4_cut3'])
c4 = c4[c4.jurisdiction == 'ME'].rename(columns={'plot_id_export': 'plot_id'})
x = c4.merge(me[['plot_id', 'PLT_CN', 'CN_label_visit', 'INVYR_label_visit']], on='plot_id', how='left')
print('CORE4 Maine training rows', len(x), 'positives', int(x.core4_cut3.sum()), 'resolved to a label visit', int(x.CN_label_visit.notna().sum()))
print('label visit INVYR (training rows):', x.INVYR_label_visit.value_counts().sort_index().to_dict())
# r0 descendant via PREV_PLT_CN, 2019-2023
child = dict(zip(plt.loc[plt.PREV_PLT_CN.notna(), 'PREV_PLT_CN'], plt.loc[plt.PREV_PLT_CN.notna(), 'CN'])); inv = dict(zip(plt.CN, plt.INVYR))
def desc(cn):
    a, hit = cn, None
    for _ in range(4):
        a = child.get(a)
        if a is None: break
        if 2019 <= inv.get(a, 0) <= 2023: hit = a
    return hit
x['CN_2023'] = [desc(c) if isinstance(c, str) else None for c in x.PLT_CN]
print('with a 2019-2023 PREV_PLT_CN descendant', int(x.CN_2023.notna().sum()), '; descendant == label visit', int((x.CN_2023 == x.CN_label_visit).sum()))
dm = pd.read_csv(f'{B}/2026-10-12_occ-ordinal-relabel/out/desc_map_RESTRICTED.csv', dtype=str)
z = x.merge(dm[['plot_id', 'CN_2023']].rename(columns={'CN_2023': 'CN_2023_r0'}), on='plot_id', how='left')
print('r0 desc_map rows matched', int(z.CN_2023_r0.notna().sum()), '; r0 CN_2023 == label visit', int((z.CN_2023_r0 == z.CN_label_visit).sum()), '; r0 CN_2023 == this walk', int((z.CN_2023_r0 == z.CN_2023).sum()))
uu = u[(u.state == 'ME') & u.INVYR.between(2019, 2023)].copy(); uu['sc'] = score(uu)
x = x.merge(uu[['CN', 'sc']].rename(columns={'CN': 'CN_2023'}), on='CN_2023', how='left')
x['new'] = np.where(x.sc.notna(), (x.sc >= 3).astype(float), np.nan)
print('scored descendant', int(x.new.notna().sum()), '; without a scored descendant', int(x.new.isna().sum()), 'of which positives', int(x[x.new.isna()].core4_cut3.sum()))
print('crosstab old (rows) vs new (cols):'); print(pd.crosstab(x.core4_cut3, x.new.fillna(-1).astype(int)).to_string())
k = x.new.notna(); print('unweighted rate old all %.2f%%, old on scored %.2f%%, new %.2f%%' % (100 * x.core4_cut3.mean(), 100 * x[k].core4_cut3.mean(), 100 * x[k].new.mean()))
# ordinal table check: r0's T0 classes vs tmp_me_v51 classes
T0 = pd.read_csv('/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-09-23/me_transitioning_training_table_DATA_2026-09-23.csv', usecols=['plot_id', 'state', 'lsog_class'])
T0 = T0[T0.state == 'ME'].merge(me[['plot_id', 'INVYR_label_visit']], on='plot_id', how='left')
print('ordinal training table (r0 input) rows', len(T0), 'label visit INVYR', T0.INVYR_label_visit.value_counts().sort_index().to_dict())
