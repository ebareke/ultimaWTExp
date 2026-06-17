# Container images

Both images bundle the **complete RNA-seq toolchain** plus the pipeline's helper
scripts, so a single container runs every process from **FASTQ → reports**. The
only host requirements are **Nextflow ≥ 23.04** and a container engine.

## Docker

```bash
# Build (from the repository root)
docker build -t ultimawtexp:1.0.0 .

# Use it via the pipeline
nextflow run .. -profile docker --input samplesheet.csv --fasta genome.fa --gtf genes.gtf

# Or invoke a bundled tool directly
docker run --rm ultimawtexp:1.0.0 STAR --version
```

Published image (after a tagged release): `ghcr.io/ebareke/ultimawtexp:1.0.0`.

## Apptainer / Singularity (HPC)

```bash
# Option A — from the published image
apptainer build ultimawtexp.sif containers/ultimawtexp.def

# Option B — from a locally-built Docker image, no registry needed
docker build -t ultimawtexp:1.0.0 .
apptainer build ultimawtexp.sif docker-daemon://ultimawtexp:1.0.0

# Use it via the pipeline
nextflow run .. -profile apptainer --input samplesheet.csv --fasta genome.fa --gtf genes.gtf
```

## Image contents (selection)

| Tool | Purpose |
|---|---|
| FastQC, fastp, Trim Galore, Cutadapt, FastQ Screen | read QC + trimming |
| STAR, HISAT2 | splice-aware alignment |
| Salmon | transcript quantification |
| samtools, Picard, Qualimap, RSeQC, preseq | alignment QC |
| featureCounts (subread), HTSeq | gene-level counting |
| STAR-Fusion | fusion detection |
| rMATS | alternative splicing |
| DESeq2, edgeR, tximport, dupRadar | differential expression / QC (R) |
| clusterProfiler, ReactomePA, msigdbr, org.\*.eg.db | enrichment (R) |
| MultiQC, Quarto | reporting |

The full pinned list is in [`environment.yml`](../environment.yml). You can also
run the pipeline outside a container with `mamba env create -f environment.yml`.
