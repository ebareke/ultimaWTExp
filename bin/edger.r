#!/usr/bin/env Rscript
# ===========================================================================
# edger.r — edgeR quasi-likelihood DE for one contrast, as a cross-check on
# DESeq2. Same inputs/contrast semantics as deseq2.r.
# ===========================================================================
suppressPackageStartupMessages({ library(edgeR) })

args <- commandArgs(trailingOnly = TRUE)
getopt <- function(flag, default = NULL) {
  i <- match(flag, args); if (is.na(i) || i == length(args)) return(default); args[i + 1]
}
counts_f  <- getopt("--counts"); design_f <- getopt("--design")
cid       <- getopt("--contrast_id"); variable <- getopt("--variable", "condition")
reference <- getopt("--reference"); target <- getopt("--target")
fdr       <- as.numeric(getopt("--fdr", "0.05"))
min_count <- as.numeric(getopt("--min_count", "10"))
blocking  <- getopt("--blocking", "")

cts <- round(as.matrix(read.delim(counts_f, row.names = 1, check.names = FALSE)))
cd  <- read.delim(design_f, row.names = 1, check.names = FALSE, stringsAsFactors = TRUE)
common <- intersect(colnames(cts), rownames(cd)); cd <- cd[common, , drop = FALSE]
cts <- cts[, common, drop = FALSE]
keep <- cd[[variable]] %in% c(reference, target)
cd <- droplevels(cd[keep, , drop = FALSE]); cts <- cts[, keep, drop = FALSE]
cd[[variable]] <- relevel(factor(cd[[variable]]), ref = reference)

terms <- variable
if (nzchar(blocking)) {
  bf <- trimws(strsplit(blocking, ",")[[1]]); bf <- bf[bf %in% colnames(cd) & bf != variable]
  for (b in bf) cd[[b]] <- factor(cd[[b]]); if (length(bf)) terms <- c(bf, variable)
}
design <- model.matrix(as.formula(paste("~", paste(terms, collapse = " + "))), data = cd)

y <- DGEList(cts)
y <- y[filterByExpr(y, design) | rowSums(y$counts) >= min_count, , keep.lib.sizes = FALSE]
y <- calcNormFactors(y)
y <- estimateDisp(y, design)
fit <- glmQLFit(y, design)
coef <- paste0(variable, target)
qlf <- glmQLFTest(fit, coef = coef)
tt  <- topTags(qlf, n = Inf)$table
out <- data.frame(gene_id = rownames(tt), tt, check.names = FALSE)
write.table(out, paste0(cid, ".edger_results.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)

pdf(paste0(cid, ".mds.pdf")); plotMDS(y, col = as.integer(cd[[variable]])); dev.off()
pdf(paste0(cid, ".bcv.pdf")); plotBCV(y); dev.off()
message("edgeR done: ", cid, " (", sum(tt$FDR < fdr, na.rm = TRUE), " significant)")
