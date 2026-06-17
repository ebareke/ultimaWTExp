# Security

## Model

ultimaWTExp is an offline analysis pipeline. It reads local FASTQ files, a local
reference (FASTA/GTF and optional indices/CTAT library), writes local results,
and makes **no network calls during analysis**. There is no server, no account,
and no telemetry. The only network activity is at *build* time (pulling the
container / conda packages) and, optionally, when a user explicitly stages
references or MSigDB gene sets.

What this leaves, and how it is handled:

| Surface | Handling |
|---|---|
| Samplesheet / design parsing | Parsed as plain CSV/TSV; validated up front (`scripts/validate_samplesheet.py`, `main.nf` checks, `REFERENCE_CHECK`). No `eval`, no shell interpolation of cell values. |
| Untrusted FASTQ/BAM | Passed to standard, widely-audited tools (STAR, HISAT2, Salmon, samtools, …); the pipeline adds no custom binary parsing. |
| Reference mismatch | `REFERENCE_CHECK` fails fast if FASTA and GTF share no contigs — preventing silent all-zero-count runs. |
| Command execution | Process scripts run under `set -euo pipefail` where applicable; a failing tool aborts (or, for the QC/report tier, is explicitly `ignore`d) rather than continuing on corrupt intermediates. |
| Containers | A single pinned bioconda/conda-forge toolchain; the helper scripts are plain Python/R with no compiled attack surface. |
| Provenance | Every run records exact tool versions and SHA-256 checksums over deliverables, enabling tamper-evidence and auditability. |
| CI workflows | Only static values and the built-in `GITHUB_TOKEN`/declared secrets reach a shell; no untrusted event input is interpolated into `run:` steps. |

Known, documented limitations:

- The pipeline trusts that input FASTQ correspond to the provided reference; it
  validates structure and sheet/reference consistency, not biological
  provenance.
- File paths in the samplesheet/params are used as given; run with inputs you
  control, as with any shell-based pipeline.

## Reporting a vulnerability

Email **eb.bioinfo@pm.me** with a description and reproduction steps.
Please do not open public issues for exploitable problems before a fix is
available. You can expect an acknowledgement within a few days; fixes are
best-effort but security reports get priority.
