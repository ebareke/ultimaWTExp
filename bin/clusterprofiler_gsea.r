#!/usr/bin/env Rscript
# ===========================================================================
# clusterprofiler_gsea.r — rank-based GSEA over the full DE list using MSigDB
# collections (HALLMARK, GO BP/MF/CC, KEGG) or a custom GMT.
#
#   clusterprofiler_gsea.r --de RES.tsv --contrast_id ID --orgdb org.Hs.eg.db \
#       --species 'Homo sapiens' --categories 'H,C5:GO:BP,...' [--gmt custom.gmt]
# ===========================================================================
suppressPackageStartupMessages({ library(clusterProfiler) })

args <- commandArgs(trailingOnly = TRUE)
getopt <- function(f, d = NULL) { i <- match(f, args); if (is.na(i) || i == length(args)) return(d); args[i + 1] }
de_f    <- getopt("--de"); cid <- getopt("--contrast_id")
orgdb   <- getopt("--orgdb"); species <- getopt("--species")
cats    <- strsplit(getopt("--categories", "H"), ",")[[1]]
gmt_f   <- getopt("--gmt", NA)

de <- read.delim(de_f, check.names = FALSE)
lfc_col <- intersect(c("log2FoldChange", "logFC"), colnames(de))[1]
ranks <- de[[lfc_col]]; names(ranks) <- de$gene_id
ranks <- sort(ranks[is.finite(ranks)], decreasing = TRUE)
if (length(ranks) < 10) { message("Too few genes for GSEA; skipping."); quit(save = "no") }

run_gsea <- function(t2g, tag) {
  res <- tryCatch(GSEA(ranks, TERM2GENE = t2g, pvalueCutoff = 1, eps = 0),
                  error = function(e) NULL)
  if (!is.null(res) && nrow(as.data.frame(res)) > 0) {
    write.table(as.data.frame(res), paste0(cid, ".gsea_", tag, ".tsv"),
                sep = "\t", quote = FALSE, row.names = FALSE)
    pdf(paste0(cid, ".gsea_", tag, "_ridge.pdf"))
    print(enrichplot::ridgeplot(res, showCategory = 20))
    dev.off()
  }
}

if (!is.na(gmt_f) && file.exists(gmt_f)) {
  run_gsea(read.gmt(gmt_f), "custom")
} else if (requireNamespace("msigdbr", quietly = TRUE) && !is.na(species) && species != "NA") {
  for (cat in cats) {
    parts <- strsplit(cat, ":")[[1]]
    msig <- tryCatch(
      msigdbr::msigdbr(species = species, category = parts[1],
                       subcategory = if (length(parts) > 1) paste(parts[-1], collapse = ":") else NULL),
      error = function(e) NULL)
    if (!is.null(msig) && nrow(msig) > 0)
      run_gsea(msig[, c("gs_name", "gene_symbol")], gsub("[:]", "_", cat))
  }
} else {
  message("No GMT and msigdbr/species unavailable; skipping GSEA.")
}
message("GSEA done: ", cid)
