# syntax=docker/dockerfile:1
#
# ultimaWTExp — production container.
#
# A single micromamba image bundling the entire RNA-seq toolchain (FastQC,
# fastp/Trim Galore/Cutadapt, STAR, HISAT2, Salmon, samtools, featureCounts,
# HTSeq, Qualimap, RSeQC, Picard, preseq, STAR-Fusion, rMATS, MultiQC, and the
# R/Bioconductor stack for DESeq2/edgeR/clusterProfiler/dupRadar) plus the
# pipeline's helper scripts, so one container runs every process from FASTQ to
# reports — no host installs beyond Nextflow + a container engine.
#
#   docker build -t ultimawtexp:1.0.0 .
#   docker run --rm ultimawtexp:1.0.0 fastqc --version
#
# Image: ghcr.io/ebareke/ultimawtexp:1.0.0 (GHCR) · ebareke/ultimawtexp:1.0.0 (Docker Hub)
# ---------------------------------------------------------------------------
FROM mambaorg/micromamba:1.5-jammy

LABEL org.opencontainers.image.title="ultimaWTExp" \
      org.opencontainers.image.description="Reproducible RNA-seq workflow — FASTQ to biological interpretation reports" \
      org.opencontainers.image.source="https://github.com/ebareke/ultimaWTExp" \
      org.opencontainers.image.url="https://ebareke.github.io/ultimaWTExp/" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.authors="Eric Bareke, Ethan M., Conrad B."

ARG MAMBA_DOCKERFILE_ACTIVATE=1
USER root

# Bioinformatics + R toolchain (pinned) via bioconda/conda-forge.
COPY environment.yml /tmp/environment.yml
RUN micromamba install -y -n base -f /tmp/environment.yml \
    && micromamba clean --all --yes

# Pipeline helper scripts (R/Python invoked by the Nextflow processes).
COPY bin/ /opt/ultimawtexp/bin/
RUN chmod +x /opt/ultimawtexp/bin/* || true

ENV PATH=/opt/conda/bin:/opt/ultimawtexp/bin:$PATH \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    XDG_CACHE_HOME=/tmp/.cache
WORKDIR /data

# Build-time smoke test — fail the build if a key tool is missing.
RUN STAR --version && salmon --version && samtools --version | head -n1 \
    && featureCounts -v 2>&1 | head -n1 \
    && Rscript -e 'library(DESeq2); cat("DESeq2", as.character(packageVersion("DESeq2")), "\n")'

CMD ["bash"]
