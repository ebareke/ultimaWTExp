# Usage

A complete reference for running ultimaWTExp: inputs, parameters, recipes and
outputs.

## Synopsis

```bash
nextflow run ebareke/ultimaWTExp \
    --input samplesheet.csv \
    --design sample_design.tsv \
    --fasta genome.fa --gtf genes.gtf \
    --organism human \
    --aligner star --pseudo_aligner salmon \
    --outdir results \
    -profile docker
```

## Inputs

### `--input` — samplesheet (CSV, required)

```csv
sample_id,fastq_1,fastq_2,strandedness
ctrl_rep1,reads/ctrl_rep1_R1.fq.gz,reads/ctrl_rep1_R2.fq.gz,reverse
ctrl_rep2,reads/ctrl_rep2_R1.fq.gz,reads/ctrl_rep2_R2.fq.gz,reverse
treat_rep1,reads/treat_rep1_R1.fq.gz,,auto
```

- `fastq_2` empty ⇒ single-end.
- `strandedness ∈ {auto, unstranded, forward, reverse}` (per-sample; falls back
  to `--strandedness`).
- Validate before running: `scripts/validate_samplesheet.py samplesheet.csv --design sample_design.tsv`.

### `--design` — sample_design.tsv (TSV, drives DE/splicing)

Mandated columns plus any covariates:

```tsv
sample_id	subject_id	condition	batch	sex	tissue	replicate
ctrl_rep1	subj1	CTRL	B1	F	liver	1
treat_rep1	subj1	TREAT	B2	M	liver	1
```

## Parameters

### Reference
| Flag | Default | Description |
|---|---|---|
| `--fasta` | — | Genome FASTA (`.fa`/`.fa.gz`) |
| `--gtf` / `--gff` | — | Annotation (GFF auto-converted) |
| `--organism` | `custom` | `human`/`mouse`/`rat`/`custom` (enrichment ID maps) |
| `--star_index` / `--hisat2_index` / `--salmon_index` | — | Reuse prebuilt indices |
| `--gene_bed` | — | RSeQC BED12 (else derived) |
| `--star_fusion_ref` | — | CTAT library (needed for fusion) |
| `--save_reference` | `true` | Publish built indices |

### Read processing
| Flag | Default | Description |
|---|---|---|
| `--trimmer` | `fastp` | `fastp`/`trimgalore`/`cutadapt`/`none` |
| `--skip_trimming` | `false` | Skip trimming entirely |
| `--save_trimmed` | `false` | Publish trimmed reads |

### Alignment & quantification
| Flag | Default | Description |
|---|---|---|
| `--aligner` | `star` | `star`/`hisat2`/`star_hisat2` |
| `--star_two_pass` | `true` | STAR 2-pass |
| `--star_chimeric` | `true` | Chimeric output (for fusion) |
| `--pseudo_aligner` | `salmon` | `salmon` or `null` |
| `--gene_quant` | `featurecounts` | `featurecounts`/`htseq`/`star` |
| `--strandedness` | `auto` | global default strandedness |

### Differential expression
| Flag | Default | Description |
|---|---|---|
| `--run_dge` | `true` | DESeq2 |
| `--run_edger` | `false` | also run edgeR |
| `--contrasts` | — | CSV `id,variable,reference,target` (else auto from `condition`) |
| `--blocking_factors` | — | comma-list of design columns for the model (e.g. `batch,subject_id`) |
| `--de_fdr` | `0.05` | adjusted-p threshold |
| `--de_lfc` | `0` | \|log2FC\| for "significant" tagging |
| `--de_min_count` | `10` | pre-filter sum-of-counts |

### Functional / fusion / splicing
| Flag | Default | Description |
|---|---|---|
| `--run_enrichment` | `true` | clusterProfiler ORA |
| `--run_gsea` | `false` | GSEA (MSigDB or `--gsea_gmt`) |
| `--enrichment_dbs` | `GO,KEGG,Reactome` | ORA databases |
| `--run_fusion` | `true` | STAR-Fusion (needs `--star_fusion_ref`) |
| `--run_splicing` | `true` | rMATS |
| `--rmats_read_length` | `100` | rMATS read length |

### QC toggles
`--skip_fastqc`, `--skip_fastq_screen`, `--skip_qualimap`, `--skip_rseqc`,
`--skip_picard`, `--skip_preseq`, `--skip_dupradar`, `--skip_multiqc`,
`--skip_report`.

### Resources
`--max_cpus` (16), `--max_memory` (128.GB), `--max_time` (72.h) — clamp every
process. Lower for a laptop, raise on a fat node.

## Profiles

Combine a **software** profile with an **executor** profile:

```bash
-profile docker            # or singularity / apptainer / podman / conda / wave
-profile slurm,apptainer   # HPC
-profile lsf,singularity
-profile test              # built-in synthetic dataset
```

## Recipes

**Paired multifactor design with batch correction**
```bash
nextflow run main.nf --input ss.csv --design design.tsv --fasta g.fa --gtf g.gtf \
    --organism mouse --blocking_factors batch,subject_id -profile docker
```

**Explicit contrasts**
```bash
# contrasts.csv: id,variable,reference,target
nextflow run main.nf ... --contrasts contrasts.csv
```

**HISAT2 + HTSeq, no fusion/splicing**
```bash
nextflow run main.nf ... --aligner hisat2 --gene_quant htseq \
    --run_fusion false --run_splicing false
```

**Resume after a failure** — add `-resume` (cached steps are reused).

## Outputs

```
results/
├── reference/                 built indices, BED12, validation report + md5
├── qc/                        fastqc, fastq_screen, samtools, picard, qualimap,
│                              rseqc, preseq, dupradar
├── trimming/                  trimmer logs (+ reads if --save_trimmed)
├── alignment/<aligner>/       sorted, indexed BAMs + logs
├── quantification/
│   ├── featurecounts|htseq    per-sample counts + summaries
│   ├── salmon/                per-sample quant
│   └── matrices/              counts.{raw,tpm,fpkm,cpm}.tsv, salmon gene matrices
├── fusion/                    STAR-Fusion predictions
├── splicing/rmats/            SE/RI/A5SS/A3SS/MXE tables
├── differential_expression/
│   ├── deseq2/<contrast>/     results, normalized counts, PCA/MA/volcano/...
│   └── edger/<contrast>/      (if --run_edger)
├── enrichment/ora|gsea/       GO/KEGG/Reactome tables + figures
├── multiqc/                   aggregated interactive report
├── reports/                   executive / technical / qc / differential HTML
├── pipeline_info/             timeline, report, trace, DAG, software versions
└── SHA256SUMS.txt             checksums over deliverables
```
