# Architecture

ultimaWTExp is a **Nextflow DSL2** pipeline built from small, single-purpose
**process modules** composed by **subworkflows**, orchestrated by one
**workflow**. The design goals are reuse, testability and runtime portability.

## Layers

```
main.nf
  └─ workflows/rnaseq.nf  (RNASEQ)
       ├─ subworkflows/local/prepare_reference.nf
       ├─ subworkflows/local/preprocessing.nf
       ├─ subworkflows/local/alignment.nf
       ├─ subworkflows/local/postalign_qc.nf
       ├─ subworkflows/local/quantification.nf
       ├─ subworkflows/local/fusion.nf
       ├─ subworkflows/local/splicing.nf
       ├─ subworkflows/local/differential_expression.nf
       ├─ subworkflows/local/functional.nf
       └─ subworkflows/local/reporting.nf
            └─ modules/local/*.nf  (one process per tool)
```

- **`main.nf`** — banner/help, fail-fast parameter validation, samplesheet
  parsing into a `(meta, [reads])` channel, then calls `RNASEQ`.
- **Workflow (`rnaseq.nf`)** — wires subworkflows, threads two accumulator
  channels (`ch_versions`, `ch_multiqc_files`) through every stage, and gates
  optional stages (fusion/splicing/DE/enrichment) on params.
- **Subworkflows** — each owns one phase and emits typed channels plus its
  `versions`/`multiqc` contributions.
- **Modules** — each wraps exactly one tool, declares inputs/outputs and a
  `versions.yml`, and **always provides a `stub:` block**.

## Key conventions

### The `meta` map
Every per-sample channel item is `tuple(meta, files)` where
`meta = [ id, single_end, strandedness ]`. Tags, output names and per-sample
flags derive from `meta`, so modules stay generic.

### `meta` vs `contrast`
Per-sample processes carry `meta`; comparison-level processes (DESeq2, edgeR,
enrichment) carry a `contrast = [id, variable, reference, target]` map. Their
`publishDir` and tags use `contrast.id`.

### Configuration is layered, not hard-coded
- `conf/base.config` — resources by `label`, with `resourceLimits` clamping.
- `conf/modules.config` — `publishDir` + default `ext.args` per process.
- `conf/genomes.config` — organism → OrgDb / KEGG / Reactome maps.
- `conf/test*.config` — the synthetic dataset.
Modules never bake in output paths or tool flags; a site retunes them here.

### Provenance & reproducibility
Each process emits `versions.yml`; `DUMP_SOFTWARE_VERSIONS` collates them (via
`collectFile`, to avoid filename collisions) into `software_versions.yml` and a
MultiQC panel. `CHECKSUMS` writes SHA-256 over the deliverables. Timeline,
report, trace and DAG are written to `pipeline_info/`.

### The stub contract
Because every process has a `stub:` block, `nextflow run -profile test
-stub-run` executes the **entire** FASTQ→reports graph with no bioinformatics
tools — this is how CI proves the topology and how you can dry-run any change.

## Data flow (channels)

```
input CSV ─▶ (meta,[reads]) ─▶ PREPROCESSING ─▶ trimmed reads
reference ─▶ fasta/gtf/indices/tx2gene/bed
trimmed + index ─▶ ALIGNMENT ─▶ (meta,bam,bai) ─┬▶ POSTALIGN_QC
                                                ├▶ QUANTIFICATION ─▶ counts.raw ─▶ DESEQ2 ─▶ FUNCTIONAL
                                                ├▶ FUSION (chimeric)
                                                └▶ SPLICING (grouped by condition)
all versions/QC ─▶ REPORTING ─▶ MultiQC + 4 HTML reports + checksums
```

## Runtime portability

The same modules run unchanged across executors (`local`/`slurm`/`pbs`/`lsf`/
`sge`/`awsbatch`/`google`) and software backends (`docker`/`singularity`/
`apptainer`/`podman`/`conda`/`wave`) — selected purely by `-profile`. One
container image carries the whole toolchain, so process definitions never depend
on host software.

## Extending the pipeline

To add a tool: create `modules/local/<tool>.nf` (script + stub + `versions.yml`),
include it in the relevant subworkflow, add its `publishDir`/`ext.args` to
`conf/modules.config`, and mix its QC output into `ch_multiqc_files`. See
[CONTRIBUTING.md](CONTRIBUTING.md). The architecture is deliberately ready for
the future stages in [ROADMAP.md](ROADMAP.md) (single-cell, long-read, spatial,
isoform discovery, multi-omics).
