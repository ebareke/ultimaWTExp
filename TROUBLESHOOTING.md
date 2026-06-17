# Troubleshooting

Most failures fall into a few categories. Start with the per-task work
directory Nextflow prints on error and inspect `.command.sh`, `.command.log`,
`.command.err`.

## Compilation / config

| Symptom | Cause | Fix |
|---|---|---|
| `Statements cannot be mixed with script declarations` / config parse errors | Nextflow ≥ 25 strict parser | `export NXF_SYNTAX_PARSER=v1` |
| `Unexpected input: '('` in a config | `def` function in config | already avoided here; don't add functions to `conf/*.config` |
| `Process requirement exceeds available CPUs` | request > host cores | lower `--max_cpus`, or run a scheduler/cloud profile |

## Inputs

| Symptom | Cause | Fix |
|---|---|---|
| `Missing --input` / `Missing reference` | required param absent | pass `--input` and `--fasta`+`--gtf` |
| `... not found` for a FASTQ | wrong path in samplesheet | paths are resolved from the **launch dir**; use absolute paths or launch from the repo root; run `scripts/validate_samplesheet.py` |
| Every gene has zero counts | genome/annotation mismatch | `REFERENCE_CHECK` fails fast on this; ensure FASTA and GTF share contig names |
| DE skipped | no `--design` or `condition` has <2 levels | provide `sample_design.tsv` with a 2+ level `condition`, or `--contrasts` |

## Alignment / quantification

| Symptom | Cause | Fix |
|---|---|---|
| STAR `EXITING: fatal error ... genomeSAindexNbases` | value too large for a small genome | the module auto-derives it; for custom indices pass `--star_index` built with the right value |
| STAR OOM-killed | index too big for the node | raise `--max_memory`; STAR needs ~32–64 GB for human |
| All reads "unstranded" / wrong counts | wrong strandedness | check RSeQC `infer_experiment`; set `strandedness` per sample or `--strandedness` |
| Fusion stage skipped | no CTAT library | pass `--star_fusion_ref`; needs `--aligner star*` and `--star_chimeric` |

## QC / R stages

| Symptom | Cause | Fix |
|---|---|---|
| preseq fails on shallow libs | too few reads | it is tolerant by default; `--skip_preseq` for tiny data |
| Enrichment produces nothing | `--organism custom` (no OrgDb) | set `--organism human/mouse/rat`, or supply `--gsea_gmt` |
| DESeq2 `every gene contains at least one zero` | ultra-sparse counts | increase depth or lower `--de_min_count`; expected on toy data |

## HPC

| Symptom | Cause | Fix |
|---|---|---|
| Jobs never start | wrong `--queue`/partition | set the executor profile's queue (`-profile slurm` + `process.queue`) |
| Container pull storms | each node pulls the SIF | set `NXF_SINGULARITY_CACHEDIR` to a shared path; pre-pull the SIF |
| Walltime kills | default time too low | raise `--max_time`; processes retry with escalating time |

## General tactics

- **`-resume`** re-uses cached steps after fixing a downstream issue.
- **`-stub-run`** confirms the topology is intact independent of tools/data.
- **`-profile test`** reproduces a known-good run for comparison.
- The run's exact tool versions are in `results/pipeline_info/software_versions.yml`.

Still stuck? Open an issue with the failing `.command.sh`/`.command.err` and the
`.nextflow.log` (see [CONTRIBUTING.md](CONTRIBUTING.md)).
