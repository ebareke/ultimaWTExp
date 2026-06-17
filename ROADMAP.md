# Roadmap

This roadmap is indicative, not a commitment. Items move as real-world datasets
and user feedback dictate. The modular architecture (see
[ARCHITECTURE.md](ARCHITECTURE.md)) is built so each item is a new module +
subworkflow wiring, not a rewrite.

## Near term

- **Published images** on GHCR and Docker Hub on every tagged release, plus a
  pre-built Apptainer SIF as an `oras://` artifact, so no local build is needed.
- **Auto strandedness** — run Salmon/RSeQC inference up front and feed the
  detected strandedness back into featureCounts/HTSeq/Picard automatically.
- **nf-schema parameter validation** — JSON-schema-driven `--help` and input
  validation once offline plugin caching is wired into CI.
- **Consensus DE reporting** — a combined DESeq2 + edgeR call table with
  agreement flags.

## Considered

- **More aligners / quantifiers** — minimap2 / Bowtie2, kallisto, RSEM,
  selectable per run.
- **Arriba** as a second fusion caller alongside STAR-Fusion.
- **rMATS visualisations** (rmats2sashimiplot) and event-level summary plots.
- **UMI handling** (the trimming layer is already UMI-aware-ready).
- **Per-process containers** (Wave/Seqera) as an alternative to the single
  monolithic image, for finer caching.
- **Genome-resource helper** to build/stage indices and CTAT libraries for
  common assemblies.

## Explicitly out of scope (for now)

- Bundling or redistributing reference genomes / annotations.
- Acting as a general-purpose aligner — alignment is delegated to STAR/HISAT2.

## Future extensions (architecture-ready)

The SRS calls for the design to accommodate, in later major versions:

- **Single-cell RNA-seq** (alevin-fry / STARsolo + Seurat/Scanpy reporting)
- **Long-read RNA-seq** (minimap2 + isoform quantification)
- **Spatial transcriptomics**
- **Isoform discovery** (StringTie / IsoQuant)
- **Multi-omics integration**

Each plugs in as additional subworkflows gated behind new `--run_*` parameters.
