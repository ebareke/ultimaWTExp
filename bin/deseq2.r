#!/usr/bin/env Rscript
# ===========================================================================
# deseq2.r — differential expression for one contrast.
#
# Builds the design from sample_design.tsv (optionally adding blocking factors
# for multifactor / paired / batch-corrected models), fits the DESeq2 GLM, and
# writes the results table, normalized counts, a run summary, and the mandated
# diagnostic plots (PCA, MA, volcano, dispersion, sample-distance heatmap).
#
# Usage:
#   deseq2.r --counts counts.raw.tsv --design sample_design.tsv \
#            --contrast_id COND_B_vs_COND_A --variable condition \
#            --reference COND_A --target COND_B \
#            [--blocking batch,subject_id] [--fdr 0.05] [--lfc 0] [--min_count 10]
# ===========================================================================
suppressPackageStartupMessages({
  library(DESeq2)
})

# ---- minimal long-flag parser --------------------------------------------
args <- commandArgs(trailingOnly = TRUE)
getopt <- function(flag, default = NULL) {
  i <- match(flag, args)
  if (is.na(i) || i == length(args)) return(default)
  args[i + 1]
}
counts_f   <- getopt("--counts")
design_f   <- getopt("--design")
cid        <- getopt("--contrast_id")
variable   <- getopt("--variable", "condition")
reference  <- getopt("--reference")
target     <- getopt("--target")
fdr        <- as.numeric(getopt("--fdr", "0.05"))
lfc        <- as.numeric(getopt("--lfc", "0"))
min_count  <- as.numeric(getopt("--min_count", "10"))
blocking   <- getopt("--blocking", "")

stopifnot(!is.null(counts_f), !is.null(design_f), !is.null(target), !is.null(reference))

# ---- load -----------------------------------------------------------------
cts <- read.delim(counts_f, row.names = 1, check.names = FALSE)
cts <- round(as.matrix(cts))
coldata <- read.delim(design_f, row.names = 1, check.names = FALSE,
                      stringsAsFactors = TRUE)

# Keep only samples present in both, restricted to the two contrast levels.
common  <- intersect(colnames(cts), rownames(coldata))
coldata <- coldata[common, , drop = FALSE]
cts     <- cts[, common, drop = FALSE]
keep_s  <- coldata[[variable]] %in% c(reference, target)
coldata <- droplevels(coldata[keep_s, , drop = FALSE])
cts     <- cts[, keep_s, drop = FALSE]

if (ncol(cts) < 2 || length(unique(coldata[[variable]])) < 2)
  stop("Contrast ", cid, ": need >=2 samples spanning both levels.")

# Reference level so log2FC is target-vs-reference.
coldata[[variable]] <- relevel(factor(coldata[[variable]]), ref = reference)

# ---- design formula (blocking factors + variable of interest last) --------
terms <- variable
if (nzchar(blocking)) {
  bf <- trimws(strsplit(blocking, ",")[[1]])
  bf <- bf[bf %in% colnames(coldata) & bf != variable]
  for (b in bf) coldata[[b]] <- factor(coldata[[b]])
  if (length(bf)) terms <- c(bf, variable)
}
form <- as.formula(paste("~", paste(terms, collapse = " + ")))
message("Contrast ", cid, " design: ", deparse(form))

# ---- fit ------------------------------------------------------------------
dds <- DESeqDataSetFromMatrix(cts, colData = coldata, design = form)
dds <- dds[rowSums(counts(dds)) >= min_count, ]
dds <- DESeq(dds)
res <- results(dds, contrast = c(variable, target, reference), alpha = fdr)
res <- res[order(res$padj), ]

resdf <- data.frame(gene_id = rownames(res), as.data.frame(res),
                    check.names = FALSE)
write.table(resdf, paste0(cid, ".deseq2_results.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE)

norm <- counts(dds, normalized = TRUE)
write.table(data.frame(gene_id = rownames(norm), norm, check.names = FALSE),
            paste0(cid, ".normalized_counts.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE)

# ---- summary --------------------------------------------------------------
sig <- with(as.data.frame(res), !is.na(padj) & padj < fdr & abs(log2FoldChange) >= lfc)
up   <- sum(sig & res$log2FoldChange > 0, na.rm = TRUE)
down <- sum(sig & res$log2FoldChange < 0, na.rm = TRUE)
writeLines(c(
  paste0("Contrast: ", cid),
  paste0("Formula : ", deparse(form)),
  paste0("Samples : ", ncol(dds), " (", target, " vs ", reference, ")"),
  paste0("Tested genes: ", nrow(res)),
  paste0("Significant (padj<", fdr, ", |lfc|>=", lfc, "): ", up + down,
         "  up=", up, " down=", down)
), paste0(cid, ".deseq2_summary.txt"))

# ---- plots ----------------------------------------------------------------
vsd <- tryCatch(vst(dds, blind = TRUE), error = function(e) rlog(dds, blind = TRUE))

pdf(paste0(cid, ".pca.pdf")); print(plotPCA(vsd, intgroup = variable)); dev.off()
pdf(paste0(cid, ".ma.pdf")); plotMA(res, main = cid); dev.off()
pdf(paste0(cid, ".dispersion.pdf")); plotDispEsts(dds); dev.off()

# Volcano (base graphics — no extra deps).
pdf(paste0(cid, ".volcano.pdf"))
with(as.data.frame(res), {
  plot(log2FoldChange, -log10(pvalue), pch = 20, col = "grey60",
       xlab = "log2 fold change", ylab = "-log10 p", main = cid)
  s <- !is.na(padj) & padj < fdr & abs(log2FoldChange) >= lfc
  points(log2FoldChange[s], -log10(pvalue)[s], pch = 20, col = "firebrick")
})
dev.off()

# Sample-distance heatmap.
sd <- as.matrix(dist(t(assay(vsd))))
pdf(paste0(cid, ".sample_distance.pdf"))
heatmap(sd, symm = TRUE, main = paste(cid, "sample distances"))
dev.off()

message("DESeq2 done: ", cid, " (", up + down, " significant genes)")
