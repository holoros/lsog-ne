import csv,sys,numpy as np
for f in sys.argv[1:]:
    R=list(csv.DictReader(open(f)))
    g=lambda r,k: float(r[k]) if r[k] not in ("","NA") else np.nan
    fh=np.array([g(r,'fh') for r in R]); sel=np.array([g(r,'sel_fixed') for r in R]); n=np.array([g(r,'n_plots') for r in R])
    w=np.array([g(r,'n_cells_sampled') for r in R]); cb=np.array([g(r,'cut_block') for r in R]); d=np.array([g(r,'direct') for r in R])
    m=(~np.isnan(sel))&(n>=2); F,S,W,D=fh[m],sel[m],w[m],d[m]
    X=np.c_[np.ones(len(F)),F]; sw=np.sqrt(W); b=np.linalg.lstsq(X*sw[:,None],S*sw,rcond=None)[0]
    tq=F>=np.quantile(F,.75); bq=F<=np.quantile(F,.25)
    tqd=D>=np.quantile(D,.75); bqd=D<=np.quantile(D,.25)
    print(f.split('/')[-1], "nfit",m.sum(),"slope %.3f"%b[1],"top %+.4f"%np.average(S[tq]-F[tq],weights=W[tq]),"bot %+.4f"%np.average(S[bq]-F[bq],weights=W[bq]),
      "cutrange %.4f %.4f"%(np.nanmin(cb),np.nanmax(cb)),"dtop %+.4f dbot %+.4f"%(np.average(S[tqd]-D[tqd],weights=W[tqd]),np.average(S[bqd]-D[bqd],weights=W[bqd])),
      "areaFH %.4f"%(np.nansum(fh*w)/np.nansum(w[~np.isnan(fh)])))
