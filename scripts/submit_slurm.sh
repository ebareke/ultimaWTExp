#!/usr/bin/env bash
# ===========================================================================
# scripts/submit_slurm.sh — launch ultimaWTExp on a SLURM cluster.
#
# Runs the Nextflow *head* job on the login/submit node (or as a small batch
# job); Nextflow itself then submits one SLURM job per process via the 'slurm'
# executor. Uses the Apptainer profile so no software is needed on the host.
#
#   scripts/submit_slurm.sh --input samplesheet.csv --fasta genome.fa --gtf genes.gtf
#
# Override the queue/partition with NXF_SLURM_QUEUE; cache the SIF once with
#   apptainer pull oras://ghcr.io/ebareke/ultimawtexp-apptainer:1.0.0
# and point NXF_SINGULARITY_CACHEDIR at a shared path.
# ===========================================================================
set -euo pipefail

export NXF_SYNTAX_PARSER="${NXF_SYNTAX_PARSER:-v1}"
export NXF_OPTS="${NXF_OPTS:--Xms1g -Xmx4g}"
export NXF_SINGULARITY_CACHEDIR="${NXF_SINGULARITY_CACHEDIR:-$PWD/.singularity}"
QUEUE="${NXF_SLURM_QUEUE:-general}"

nextflow run main.nf \
    -profile slurm,apptainer \
    -work-dir "${NXF_WORK:-$PWD/work}" \
    -resume \
    --max_cpus "${MAX_CPUS:-32}" \
    --max_memory "${MAX_MEMORY:-256.GB}" \
    --max_time "${MAX_TIME:-72.h}" \
    "$@"
