#!/usr/bin/env Rscript
# ===========================================================================
# clusterprofiler_ora.r — over-representation analysis of significant DE genes
# against GO (BP/MF/CC), KEGG and Reactome.
#
#   clusterprofiler_ora.r --de RES.tsv --contrast_id ID --orgdb org.Hs.eg.db \
#       --kegg hsa --databases 'GO,KEGG,Reactome' --fdr 0.05 --de_fdr 0.05
# ===========================================================================
suppressPackageStartupMessages({ library(clusterProfiler) })

args <- commandArgs(trailingOnly = TRUE)
getopt <- function(f, d = NULL) { i <- match(f, args); if (is.na(i) || i == length(args)) return(d); args[i + 1] }
de_f   <- getopt("--de"); cid <- getopt("--contrast_id")
orgdb  <- getopt("--orgdb"); kegg <- getopt("--kegg")
dbs    <- strsplit(getopt("--databases", "GO,KEGG,Reactome"), ",")[[1]]
fdr    <- as.numeric(getopt("--fdr", "0.05"))
de_fdr <- as.numeric(getopt("--de_fdr", "0.05"))

suppressPackageStartupMessages(library(orgdb, character.only = TRUE))
OrgDb <- get(orgdb)

de <- read.delim(de_f, check.names = FALSE)
padj_col <- intersect(c("padj", "FDR", "adj.P.Val"), colnames(de))[1]
sig <- de$gene_id[!is.na(de[[padj_col]]) & de[[padj_col]] < de_fdr]
universe <- de$gene_id
message("ORA ", cid, ": ", length(sig), " significant of ", length(universe))
if (length(sig) < 3) { message("Too few DE genes; skipping ORA."); quit(save = "no") }

# Map whatever id we have (SYMBOL or ENSEMBL) to ENTREZ for KEGG/Reactome.
to_entrez <- function(ids) {
  for (kt in c("ENSEMBL", "SYMBOL", "ENTREZID")) {
    m <- tryCatch(bitr(ids, kt, "ENTREZID", OrgDb = OrgDb), error = function(e) NULL)
    if (!is.null(m) && nrow(m) > 0) return(unique(m$ENTREZID))
  }
  character(0)
}
keytype <- if (all(grepl("^ENSG|^ENSMUS|^ENSRNO", head(universe)))) "ENSEMBL" else "SYMBOL"
write_res <- function(obj, tag) {
  if (!is.null(obj) && nrow(as.data.frame(obj)) > 0) {
    write.table(as.data.frame(obj), paste0(cid, ".ora_", tag, ".tsv"),
                sep = "\t", quote = FALSE, row.names = FALSE)
    pdf(paste0(cid, ".ora_", tag, "_dotplot.pdf"))
    print(dotplot(obj, showCategory = 20) + ggplot2::ggtitle(paste(cid, tag)))
    dev.off()
  }
}

if ("GO" %in% dbs) {
  for (ont in c("BP", "MF", "CC")) {
    ego <- tryCatch(enrichGO(sig, OrgDb = OrgDb, keyType = keytype, ont = ont,
                             universe = universe, pAdjustMethod = "BH", qvalueCutoff = fdr),
                    error = function(e) NULL)
    write_res(ego, paste0("GO_", ont))
  }
}
if (any(c("KEGG", "Reactome") %in% dbs)) {
  sig_e <- to_entrez(sig)
  if (length(sig_e) >= 3) {
    if ("KEGG" %in% dbs && !is.na(kegg) && kegg != "NA") {
      ek <- tryCatch(enrichKEGG(sig_e, organism = kegg, pvalueCutoff = fdr),
                     error = function(e) NULL)
      write_res(ek, "KEGG")
    }
    if ("Reactome" %in% dbs && requireNamespace("ReactomePA", quietly = TRUE)) {
      er <- tryCatch(ReactomePA::enrichPathway(sig_e, pvalueCutoff = fdr, readable = TRUE),
                     error = function(e) NULL)
      write_res(er, "Reactome")
    }
  }
}
message("ORA done: ", cid)
