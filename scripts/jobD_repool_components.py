import csv, math, collections
AC2HA=0.40468564224
rows=list(csv.DictReader(open('jobD_components_raw.csv')))
agg=collections.defaultdict(lambda:[0.0]*5)
for r in rows:
    ev=int(r['evalid']); es='x2301' if (ev//100)%100==23 else 'x2401'
    k=(r['grouping'],es,r['domain'],r['grp'])
    v=agg[k]
    for i,c in enumerate(['TY','TX','VY','VX','CXY']): v[i]+=float(r[c])
out=collections.defaultdict(list)
for (g,es,dom,grp),(TY,TX,VY,VX,CXY) in agg.items():
    if TX<=0: continue
    R=TY/TX; varR=(VY-2*R*CXY+R*R*VX)/TX**2
    se=100*math.sqrt(max(varR,0)); pct=100*R
    out[g].append(dict(evalid_set=es,domain=dom,group=grp,
        forest_kha=round(TX*AC2HA/1000), pct=round(pct,1),
        lo=round(max(0,pct-1.96*se),1), hi=round(pct+1.96*se,1),
        se=round(se,3), truelsog_kha=round(TY*AC2HA/1000)))
names={'FORTGRP':'jobD_pooled_fortype.csv','ECO_L3':'jobD_pooled_ecoregion.csv','allgrp':'jobD_pooled_overall.csv'}
for g,fn in names.items():
    rs=sorted(out[g],key=lambda d:(d['evalid_set'],d['domain'],-d['forest_kha']))
    with open(fn,'w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=['evalid_set','domain','group','forest_kha','pct','lo','hi','se','truelsog_kha'])
        w.writeheader(); w.writerows(rs)
    print('WROTE',fn,len(rs))
