#!/usr/bin/env Rscript
# ===========================================================================
# run_tximport.r — summarise Salmon transcript quant to gene level.
#
#   run_tximport.r <salmon_dir> <tx2gene.tsv> <out_prefix>
#
# <salmon_dir> contains one sub-directory per sample (each with quant.sf).
# Emits <prefix>.gene_counts.tsv, <prefix>.gene_tpm.tsv, <prefix>.transcript_tpm.tsv
# ===========================================================================
suppressPackageStartupMessages({ library(tximport) })

a <- commandArgs(trailingOnly = TRUE)
salmon_dir <- a[1]; tx2gene_f <- a[2]; prefix <- ifelse(length(a) >= 3, a[3], "salmon")

samples <- list.dirs(salmon_dir, recursive = FALSE, full.names = TRUE)
files <- file.path(samples, "quant.sf")
names(files) <- sub("_salmon$", "", basename(samples))
files <- files[file.exists(files)]
stopifnot(length(files) > 0)

t2g <- read.delim(tx2gene_f, header = FALSE)[, 1:2]

txi_g <- tximport(files, type = "salmon", tx2gene = t2g,
                  countsFromAbundance = "lengthScaledTPM")
txi_t <- tximport(files, type = "salmon", txOut = TRUE)

wr <- function(mat, idname, path) {
  df <- data.frame(setNames(list(rownames(mat)), idname), mat, check.names = FALSE)
  write.table(df, path, sep = "\t", quote = FALSE, row.names = FALSE)
}
wr(round(txi_g$counts, 3), "gene_id", paste0(prefix, ".gene_counts.tsv"))
wr(round(txi_g$abundance, 3), "gene_id", paste0(prefix, ".gene_tpm.tsv"))
wr(round(txi_t$abundance, 3), "tx_id", paste0(prefix, ".transcript_tpm.tsv"))
message("tximport done: ", length(files), " samples")
