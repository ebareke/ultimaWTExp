# ultimaWTExp

**A production-grade, fully reproducible RNA-seq analysis platform — from raw FASTQ to final biological-interpretation reports.**

`ultimaWTExp` is a **Nextflow DSL2** pipeline that takes raw paired- or
single-end **FASTQ files all the way to differential expression, alternative
splicing, gene fusions, functional enrichment and audience-specific HTML
reports** — in one command, on a laptop or across SLURM / PBS / LSF / SGE
clusters, entirely inside immutable containers.

[![CI](https://github.com/ebareke/ultimaWTExp/actions/workflows/ci.yml/badge.svg)](https://github.com/ebareke/ultimaWTExp/actions/workflows/ci.yml)
[![Containers](https://github.com/ebareke/ultimaWTExp/actions/workflows/containers.yml/badge.svg)](https://github.com/ebareke/ultimaWTExp/actions/workflows/containers.yml)
![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A523.04-23aa62)
![License](https://img.shields.io/badge/license-MIT-blue)
![Platforms](https://img.shields.io/badge/platform-linux%20%7C%20macOS%20%7C%20HPC-lightgrey)
[![Docs](https://img.shields.io/badge/docs-ebareke.github.io-1E6B4F)](https://ebareke.github.io/ultimaWTExp/)

Documentation: **<https://ebareke.github.io/ultimaWTExp/>**

---

## Features

- 🧬 **FASTQ → interpretation, one command** — QC, trimming, alignment,
  quantification, fusion, splicing, differential expression, enrichment and
  reports, wired as reusable Nextflow DSL2 modules and subworkflows.
- 🧰 **Choice of tools at every stage** — aligners **STAR** (2-pass, chimeric)
  and **HISAT2**; quantifiers **featureCounts / HTSeq / STAR** (gene) and
  **Salmon** (transcript, via tximport); trimmers **fastp / Trim Galore /
  Cutadapt**.
- 📊 **Full QC battery → MultiQC** — FastQC, fastp, samtools, Picard, Qualimap,
  RSeQC, preseq, dupRadar, all aggregated into one interactive report.
- 🔬 **Downstream biology** — **DESeq2** (+ optional **edgeR**) metadata-driven
  DE, **STAR-Fusion**, **rMATS** (SE/RI/A5SS/A3SS/MXE), and **clusterProfiler**
  ORA (GO/KEGG/Reactome) + optional GSEA.
- 📝 **Four audience reports** — Executive, Technical, QC and Differential, plus
  PCA / MA / volcano / dispersion / heatmap figures.
- 🖥️ **Laptop *and* HPC *and* cloud** — `local`, `slurm`, `pbs`, `lsf`, `sge`,
  `awsbatch`, `google` executors; `-resume`, per-process resource profiles.
- 📦 **Immutable containers** — one Docker / Apptainer image bundles the
  toolchain (STAR-Fusion and rMATS run from their own pinned upstream images);
  no host installs beyond Nextflow + a container engine.
- 🔁 **Reproducible** — version-pinned environment, recorded software versions,
  SHA-256 checksums over deliverables, and a tool-free `-stub-run` that
  validates the whole topology in CI.

## Quick start

```bash
# 1. Install Nextflow (>=23.04) + a container engine (Docker / Apptainer)
# 2. Run on your data
nextflow run ebareke/ultimaWTExp \
    --input samplesheet.csv \
    --design sample_design.tsv \
    --fasta genome.fa --gtf genes.gtf \
    --organism human \
    -profile docker
```

### Try the bundled synthetic example (no references needed)

```bash
git clone https://github.com/ebareke/ultimaWTExp.git && cd ultimaWTExp
bash examples/run_example.sh        # real run in a container, or -stub-run fallback
```

### Validate the whole topology without any tools

```bash
python3 examples/scripts/make_synthetic.py
NXF_SYNTAX_PARSER=v1 nextflow run main.nf -profile test -stub-run
```

## Inputs

**`--input` samplesheet (CSV):**

```csv
sample_id,fastq_1,fastq_2,strandedness
ctrl_rep1,reads/ctrl_rep1_R1.fq.gz,reads/ctrl_rep1_R2.fq.gz,reverse
treat_rep1,reads/treat_rep1_R1.fq.gz,,auto
```

`fastq_2` empty ⇒ single-end. `strandedness ∈ {auto, unstranded, forward, reverse}`.

**`--design` sample_design.tsv** (drives DE / splicing) — mandated columns
`sample_id, subject_id, condition, batch, sex, tissue, replicate`, plus any
user-defined covariates.

## Pipeline

```
FASTQ ─▶ FastQC ─▶ trim ─▶ FastQC ─▶ STAR / HISAT2 ─▶ BAM
                                          │
   ┌──────────────────────────────────────┼───────────────────────────┐
   ▼                  ▼                    ▼                ▼           ▼
post-align QC   featureCounts/HTSeq    Salmon→tximport  STAR-Fusion   rMATS
(Picard,Qualimap,    │ STAR counts        │                │           │
 RSeQC,preseq,       ▼                    ▼                ▼           ▼
 dupRadar)      counts (raw/TPM/      DESeq2 (+edgeR) ─▶ clusterProfiler (ORA/GSEA)
   │             FPKM/CPM)                │
   └───────────────────────┬─────────────┴────────────────┬───────────┘
                           ▼                               ▼
                        MultiQC                 Executive/Technical/QC/DE reports
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for the module/subworkflow layout.

## Project layout

```
main.nf              entrypoint (validation, samplesheet parsing)
workflows/rnaseq.nf  the end-to-end workflow
subworkflows/local/  reference, preprocessing, alignment, post-align QC,
                     quantification, fusion, splicing, DE, functional, reporting
modules/local/       one process per tool (script + stub)
conf/                base / modules / genomes / test configs + executor profiles
bin/                 R + Python analysis scripts (DESeq2, edgeR, tximport,
                     clusterProfiler, dupRadar, count merge, version collation)
assets/report/       Quarto report templates
containers/          Apptainer definition + docs   |   Dockerfile, environment.yml
examples/            synthetic dataset + runner     |   tests/  tool-free suite
```

## Documentation

| File | Contents |
|---|---|
| [INSTALLATION.md](INSTALLATION.md) | Install Nextflow, containers, references |
| [USAGE.md](USAGE.md) | Full parameter + recipe reference |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Module / subworkflow design |
| [FAQ.md](FAQ.md) | Common questions |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Diagnosing failures |
| [RELEASE_PROCESS.md](RELEASE_PROCESS.md) | How releases are cut |
| [ROADMAP.md](ROADMAP.md) · [CHANGELOG.md](CHANGELOG.md) | Plans · history |
| [CONTRIBUTING.md](CONTRIBUTING.md) · [SECURITY.md](SECURITY.md) | Contributing · security |

## Authors

- **Eric B.** — <eb.bioinfo@pm.me>
- **Ethan M.** — <eb.bioinfo@pm.me>
- **Conrad S.** — <eb.bioinfo@pm.me>

## License

[MIT](LICENSE) © 2026 Eric Bareke, Ethan M., and Conrad B.
