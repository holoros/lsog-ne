# =============================================================================
# Phase 25: "What is true LSOG?" Is old-growth one axis or many? On the 463
# archived training plots, examine the correlation structure and dimensionality
# of the ground attributes that define LSOG (live structure, large trees,
# diameter diversity, dead wood). If the axes decouple, no single proxy (least of
# all canopy height) can capture the condition. Output: ~/LSOG/output_phase25/
# =============================================================================
suppressPackageStartupMessages({ library(data.table); library(ggplot2); library(ggsci) })
TRAIN<-"/users/PUOM0008/crsfaaron/LSOG/data/zenodo_hagan/Maine_training_data.csv"
OUT<-"/users/PUOM0008/crsfaaron/LSOG/output_phase25"; dir.create(OUT,showWarnings=FALSE,recursive=TRUE)
d<-fread(TRAIN)
vars<-c(sum_live_basalarea="Live basal area",
        basal_GE_40cmDBH="Large-tree basal area (>=40 cm)",
        No_treesGE_40cmdbh="No. large trees (>=40 cm)",
        QMD_live="Quadratic mean diameter",
        CV_livedbh="Diameter diversity (CV dbh)",
        sum_dead_basalarea="Standing dead basal area (snags)",
        CWD_vol="Coarse woody debris volume")
X<-as.matrix(d[, names(vars), with=FALSE]); colnames(X)<-vars
X<-X[complete.cases(X),]
C<-cor(X, method="spearman")
fwrite(data.table(attribute=rownames(C), as.data.table(round(C,2))), file.path(OUT,"D1_lsog_attribute_correlations.csv"))
# dimensionality: PCA on scaled attributes
pca<-prcomp(X, scale.=TRUE)
ve<-round(100*pca$sdev^2/sum(pca$sdev^2),1)
fwrite(data.table(PC=paste0("PC",seq_along(ve)), var_explained_pct=ve,
                  cum_pct=round(cumsum(ve),1)), file.path(OUT,"D2_pca_variance.csv"))
cat("PC1..3 variance explained:", paste(ve[1:3],collapse=", "), "%\n")
cat("live-structure vs dead-wood correlations:\n")
print(round(C[c("Large-tree basal area (>=40 cm)","Quadratic mean diameter"),
             c("Standing dead basal area (snags)","Coarse woody debris volume")],2))

# ---- heatmap figure (GSEA centered at 0) ----
ord<-c("Live basal area","Large-tree basal area (>=40 cm)","No. large trees (>=40 cm)",
       "Quadratic mean diameter","Diameter diversity (CV dbh)",
       "Standing dead basal area (snags)","Coarse woody debris volume")
m<-as.data.table(as.table(C)); setnames(m,c("v1","v2","r"))
m[, v1:=factor(v1,levels=ord)][, v2:=factor(v2,levels=rev(ord))]
p<-ggplot(m, aes(v1,v2,fill=r))+geom_tile(color="white")+
  geom_text(aes(label=sprintf("%.2f",r)), size=2.8)+
  scale_fill_gradientn(colors=pal_gsea()(12), limits=c(-1,1), name="Spearman r")+
  labs(title="Old growth is a dominant gradient plus partially independent dimensions",
       subtitle=sprintf("463 plots: a stand-development gradient (PC1, %.0f%%) plus off-axis structure (PC2+, %.0f%%); live structure and dead wood share only ~%.0f%% of variance (r about 0.5).", ve[1], 100-ve[1], 100*0.5^2),
       x=NULL,y=NULL)+
  theme_minimal(base_size=10)+theme(panel.grid=element_blank(),
    axis.text.x=element_text(angle=35,hjust=1,size=8), axis.text.y=element_text(size=8),
    plot.background=element_rect(fill="white",color=NA), plot.subtitle=element_text(size=8,color="grey35"))
ggsave(file.path(OUT,"Fig_dimensions.png"), p, width=6.6, height=5.4, dpi=300)
ggsave(file.path(OUT,"Fig_dimensions_thumb.jpg"), p, width=6.6, height=5.4, dpi=70)
cat("PHASE 25 DONE\n")
