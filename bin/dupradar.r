#!/usr/bin/env Rscript
# ===========================================================================
# dupradar.r — duplication-vs-expression QC.
#   dupradar.r <bam> <sample_id> <gtf> <strand:0|1|2> <single|paired> <threads>
# ===========================================================================
suppressPackageStartupMessages({ library(dupRadar) })

a <- commandArgs(trailingOnly = TRUE)
bam <- a[1]; sid <- a[2]; gtf <- a[3]
strand <- as.integer(a[4]); paired <- identical(a[5], "paired")
threads <- as.integer(ifelse(length(a) >= 6, a[6], "1"))

dm <- analyzeDuprates(bam, gtf, strand, paired, threads)
write.table(dm, paste0(sid, "_dupMatrix.txt"), sep = "\t", quote = FALSE, row.names = FALSE)

pdf(paste0(sid, "_duprateExpDens.pdf"))
duprateExpDensPlot(dm, main = sid)
dev.off()

fit <- duprateExpFit(dm)
writeLines(c(
  paste0("sample\t", sid),
  paste0("intercept\t", signif(fit$intercept, 5)),
  paste0("slope\t", signif(fit$slope, 5))
), paste0(sid, "_intercept_slope.txt"))
message("dupRadar done: ", sid)
