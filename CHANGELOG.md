# Changelog

All notable changes to ultimaWTExp are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project adheres
to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.0.0] — 2026-06-16

First public release — a complete, reproducible RNA-seq analysis platform built
on Nextflow DSL2.

### Added

- **End-to-end Nextflow DSL2 pipeline**: FASTQ → QC → trimming → alignment →
  quantification → post-alignment QC → fusion → splicing → differential
  expression → functional enrichment → reports, composed from reusable modules
  and subworkflows.
- **Pre-alignment QC & trimming**: FastQC (raw + trimmed), optional FastQ
  Screen, and a choice of trimmer — **fastp** (default), **Trim Galore** or
  **Cutadapt** — with polyG/polyX removal.
- **Reference management**: FASTA/GTF(/GFF) handling with up-front
  genome/annotation **consistency validation** and checksums; on-the-fly STAR,
  HISAT2 and decoy-aware Salmon index building (or reuse prebuilt); BED12
  derivation for RSeQC.
- **Alignment**: **STAR** (2-pass, chimeric output, native gene counts) and
  **HISAT2** (splice-aware), coordinate-sorted and indexed.
- **Post-alignment QC**: samtools stats/flagstat/idxstats, Picard
  MarkDuplicates + CollectRnaSeqMetrics, Qualimap rnaseq, RSeQC battery
  (strandedness, gene-body coverage, junction saturation, read distribution),
  preseq and dupRadar — all aggregated by **MultiQC**.
- **Quantification**: gene-level **featureCounts / HTSeq / STAR** and
  transcript-level **Salmon → tximport**, merged into **raw / TPM / FPKM / CPM**
  matrices.
- **Fusion detection**: **STAR-Fusion** from STAR chimeric junctions.
- **Alternative splicing**: **rMATS** for SE/RI/A5SS/A3SS/MXE between condition
  groups.
- **Differential expression**: metadata-driven **DESeq2** (+ optional
  **edgeR**) with auto- or file-defined contrasts and blocking factors for
  multifactor / paired / batch-corrected models; PCA, MA, volcano, dispersion
  and sample-distance plots.
- **Functional interpretation**: **clusterProfiler** ORA (GO BP/MF/CC, KEGG,
  Reactome) and optional GSEA (MSigDB or custom GMT).
- **Reporting**: four audience-specific HTML reports (Executive, Technical, QC,
  Differential) via Quarto/RMarkdown, plus MultiQC.
- **Reproducibility**: single immutable Docker/Apptainer image bundling the full
  toolchain, version-pinned `environment.yml`, per-run software-version capture,
  and SHA-256 checksums over deliverables.
- **Portability**: `local`, `slurm`, `pbs`, `lsf`, `sge`, `awsbatch`, `google`
  executors and `docker`/`singularity`/`apptainer`/`podman`/`conda`/`wave`
  software profiles; resource ceilings via `resourceLimits`.
- **Tool-free verification**: a `stub:` block on every process so
  `nextflow -profile test -stub-run` validates the entire topology with no
  bioinformatics tools, plus a pure bash/python assertion suite.
- **Synthetic example**: a deterministic 3-gene genome with 6 paired-end samples
  across two conditions for CI and demonstrations.
- **CI**: config + script lint, a stub-run matrix across Nextflow versions, the
  assertion suite, and container/Apptainer build-and-publish workflows
  (Docker Hub + GHCR).
- **Documentation**: README, INSTALLATION, USAGE, ARCHITECTURE, FAQ,
  TROUBLESHOOTING, RELEASE_PROCESS, ROADMAP, CONTRIBUTING, CODE_OF_CONDUCT,
  SECURITY, CITATION and a published docs site.
