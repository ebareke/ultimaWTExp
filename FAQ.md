# FAQ

**Q. What does ultimaWTExp do, in one sentence?**
Takes RNA-seq FASTQ files to differential expression, splicing, fusions,
enrichment and HTML reports, reproducibly, with one Nextflow command.

**Q. Do I need to install STAR, Salmon, DESeq2, …?**
No. One container image bundles the entire toolchain. You only install Nextflow
and a container engine (Docker or Apptainer). A `conda` profile is also provided.

**Q. Does it download reference genomes?**
No — by design it is offline and redistributes nothing. You supply `--fasta` and
`--gtf` (and a CTAT library if you want fusion detection). Set `--organism` so
enrichment can map IDs.

**Q. How are differential-expression comparisons chosen?**
Either explicitly via a `--contrasts` CSV (`id,variable,reference,target`), or
automatically from the `condition` column of `sample_design.tsv` (each non-
reference level vs the alphabetically-first level). Add `--blocking_factors
batch,subject_id` for multifactor / paired / batch-corrected models.

**Q. STAR vs HISAT2 — which aligner?**
STAR (default) is the most sensitive and is required for STAR-Fusion; HISAT2 is
lighter on memory. Use `--aligner star_hisat2` to build/run both.

**Q. featureCounts vs HTSeq vs STAR vs Salmon?**
`--gene_quant` picks the primary gene matrix (featureCounts default). Salmon
(`--pseudo_aligner salmon`) adds transcript-level estimates summarised to genes
by tximport. All produce raw/TPM/FPKM/CPM matrices.

**Q. Can I run it on a cluster?**
Yes: `-profile slurm,apptainer` (or `pbs`/`lsf`/`sge`). The head job submits one
scheduler job per process. `scripts/submit_slurm.sh` is a ready wrapper.

**Q. I'm on Nextflow 25/26 and it won't compile.**
Set `export NXF_SYNTAX_PARSER=v1` (the pipeline uses classic DSL2 syntax). CI and
the helper scripts set this automatically.

**Q. How do I test it without real data or tools?**
`bash tests/test_pipeline.sh` (pure bash/python) and
`nextflow run main.nf -profile test -stub-run` (full topology, no tools).

**Q. How big a machine do I need?**
A human STAR index needs ~32–64 GB RAM. Tune with `--max_cpus/--max_memory/
--max_time`; processes auto-scale and retry on transient failures.

**Q. Is the output reproducible?**
Same inputs + same container = same outputs. Software versions are recorded per
run and deliverables are checksummed (`SHA256SUMS.txt`).

**Q. Can I add a new tool / step?**
Yes — see [ARCHITECTURE.md](ARCHITECTURE.md) and [CONTRIBUTING.md](CONTRIBUTING.md).

**Q. What about single-cell / long-read / spatial?**
Out of scope for 1.0 but the modular architecture is built to accommodate them —
see [ROADMAP.md](ROADMAP.md).
