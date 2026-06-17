#!/usr/bin/env bash
#
# End-to-end example for ultimaWTExp.
#
# 1. Generates a tiny synthetic genome + GTF + 6 paired-end samples
#    (examples/scripts/make_synthetic.py).
# 2. Runs the pipeline on them.
#
# If a container engine is available the example runs the REAL pipeline inside
# the bundled image; otherwise it falls back to `-stub-run`, which exercises the
# whole topology without any bioinformatics tools. For a real run install
# Nextflow + Docker/Apptainer (the image bundles every tool) — see
# docs/INSTALLATION.md.
#
# Usage:   bash examples/run_example.sh [extra nextflow args...]

set -euo pipefail
export NXF_SYNTAX_PARSER="${NXF_SYNTAX_PARSER:-v1}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
cd "$ROOT"

echo ">> [1/2] Generating synthetic dataset"
python3 examples/scripts/make_synthetic.py

PROFILE="test"
MODE="-stub-run"
if command -v docker >/dev/null 2>&1; then
    PROFILE="test,docker"; MODE=""
    echo ">> Docker found — running the real pipeline in the container."
elif command -v apptainer >/dev/null 2>&1 || command -v singularity >/dev/null 2>&1; then
    PROFILE="test,apptainer"; MODE=""
    echo ">> Apptainer found — running the real pipeline in the container."
else
    echo ">> No container engine found — running in -stub-run mode."
    echo ">> (install Docker/Apptainer for a real end-to-end run)"
fi

echo ">> [2/2] Running ultimaWTExp (-profile ${PROFILE} ${MODE})"
nextflow run main.nf -profile "${PROFILE}" ${MODE} --outdir example_results "$@"

echo ">> Done. Results in: example_results/"
echo ">>   QC report : example_results/multiqc/multiqc_report.html"
echo ">>   Reports   : example_results/reports/"
echo ">>   DE tables : example_results/differential_expression/"
