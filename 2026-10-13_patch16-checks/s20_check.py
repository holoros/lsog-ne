# Aggregate-only check (Oct 13, 2026): class column of the Sep 23 training table vs its own total_score, and step1 total-score classes vs jobA classes.
import pandas as pd, numpy as np
T0='/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-09-23/me_transitioning_training_table_DATA_2026-09-23.csv'
t=pd.read_csv(T0,usecols=lambda c: not c.startswith('AE')); t=t[t.state=='ME']
n=pd.read_csv('/users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/out/me_training_table_relabel2023_RESTRICTED.csv',usecols=['plot_id','total_score','lsog_class'])
cl=lambda s: np.select([s>=8,s>=6,s>=4],['OG','LS','Transitioning LS'],'Not LSOG')
t['cls_from_score']=cl(t.total_score)
a=t.groupby(['lsog_class','cls_from_score']).size().rename('n').reset_index(); a.insert(0,'table','sep23_class_column_vs_own_score_3062'); 
x=t.merge(n,on='plot_id',suffixes=('_o','_n')); x['c1']=cl(x.total_score_o)
b=x.groupby(['c1','lsog_class_n']).size().rename('n').reset_index().rename(columns={'c1':'lsog_class','lsog_class_n':'cls_from_score'}); b.insert(0,'table','step1_score_class_vs_jobA_class_2977')
s=pd.DataFrame([{'table':'summary','lsog_class':'trans_plus_agree_step1_vs_jobA','cls_from_score':'','n':int(((x.total_score_o>=4)==(x.total_score_n>=4)).sum())},
                {'table':'summary','lsog_class':'class_agree_step1_vs_jobA','cls_from_score':'','n':int((x.c1==x.lsog_class_n).sum())},
                {'table':'summary','lsog_class':'class_agree_sep23column_vs_jobA','cls_from_score':'','n':int((x.lsog_class_o==x.lsog_class_n).sum())},
                {'table':'summary','lsog_class':'sep23column_ne_own_score_class','cls_from_score':'','n':int((t.lsog_class!=t.cls_from_score).sum())},
                {'table':'summary','lsog_class':'plots_merged','cls_from_score':'','n':len(x)}])
pd.concat([a,b,s]).to_csv('out/s20_class_source_check_DATA_2026-10-13.csv',index=False)
