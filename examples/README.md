# Example: synthetic end-to-end run

This directory contains a **deterministic, tiny RNA-seq dataset** and a one-shot
runner so you can exercise the whole pipeline in minutes.

```bash
bash examples/run_example.sh
```

What it does:

1. `scripts/make_synthetic.py` writes into `data/`:
   - `genome.fa` — a ~12 kb single contig (`chr1`) with three genes
   - `genes.gtf` — gene/transcript/exon annotation (2 exons/gene)
   - six paired-end samples (`ctrl_rep{1,2,3}`, `treat_rep{1,2,3}`)
   - `samplesheet.csv` — `sample_id,fastq_1,fastq_2,strandedness`
   - `sample_design.tsv` — the mandated metadata (`sample_id, subject_id,
     condition, batch, sex, tissue, replicate`)
2. Runs `nextflow run main.nf -profile test`:
   - inside the container if Docker/Apptainer is present (a **real** run), or
   - `-stub-run` otherwise (validates the full topology without any tools).

The expression program up-regulates `geneB` and down-regulates `geneC` in the
TREAT group, so a real run recovers them as differentially expressed in the
`TREAT_vs_CTRL` contrast — a reproducible fixture for the acceptance tests.

Outputs land in `example_results/` (QC in `multiqc/`, reports in `reports/`,
DE tables in `differential_expression/`).

> The generated `data/*` files are git-ignored; they are reproduced byte-for-byte
> by the generator (fixed RNG seed), which is itself a reproducibility check.
