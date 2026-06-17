# Software Requirements Specification
## Research Lab RNA-seq Analysis Platform
### End-to-End Workflow from FASTQ Files to Final Reports and Deliverables

Version: 1.0
Language: English

---

# 1. Project Overview

## 1.1 Objective

The objective of this project is to design, develop, validate, document, and deliver a production-grade, fully reproducible, portable, and scalable RNA-seq analysis platform capable of processing raw FASTQ files through final biological interpretation reports.

The solution shall be suitable for academic, clinical-research, government, and industrial environments and must follow software engineering best practices, reproducibility standards, and modern workflow management principles.

The delivered solution must be turnkey, fully containerized, extensively documented, tested, and deployable on HPC clusters and Linux servers without requiring software installation outside the provided containers.

---

# 2. General Scope

The contractor shall design and deliver:

1. A complete Nextflow-based RNA-seq workflow.
2. Modular analysis components.
3. Fully isolated Docker images (built locally).
4. Fully isolated Apptainer/Singularity images.
5. Validation datasets.
6. Example datasets.
7. Complete user documentation.
8. Developer documentation.
9. Automated testing suite.
10. CI/CD infrastructure.
11. Dynamic HTML reports.
12. Reproducible final deliverables.
13. Git repository with professional documentation (Repository to use: 'https://github.com/ebareke/ultimaWTExp') - use same (Github + Docker) credentials and contributor information as the ones used in '/Users/ebareke/Documents/Projects/ultimaC4walker' - No Claude trailer, no 'claude' co-author (at all).
14. Long-term maintenance roadmap.

---

# 3. Technical Requirements

## 3.1 Workflow Engine

Mandatory:

- Nextflow DSL2
- Modular architecture
- Reusable modules
- Channel-based design
- Support for pipeline resume
- Workflow versioning
- Parameter validation

The workflow must support:

- Local execution
- SLURM
- PBS
- LSF
- SGE
- Cloud-ready architecture

---

# 4. Input Data Requirements

## 4.1 Accepted Inputs

### Sequencing Data

- FASTQ.gz
- Single-end
- Paired-end

### Metadata

Mandatory:

sample_design.tsv

Minimum fields:

- sample_id
- subject_id
- condition
- batch
- sex
- tissue
- replicate

Configurable user-defined covariates.

---

# 5. Pre-Alignment Quality Control

Required tools:

- FastQC
- FastQ Screen (optional)
- MultiQC

Metrics:

- Read counts
- Base quality
- GC content
- Adapter contamination
- Duplication rates
- Overrepresented sequences

Deliverables:

- Individual FastQC reports
- Aggregated MultiQC report

---

# 6. Read Processing

Optional preprocessing:

- fastp
- Trim Galore
- Cutadapt

Capabilities:

- Adapter trimming
- Quality trimming
- PolyG removal
- PolyX removal
- UMI handling (future-ready)

---

# 7. Reference Management

Support:

- Human
- Mouse
- Rat
- Custom organisms

Inputs:

- Genome FASTA
- GTF/GFF3

Capabilities:

- Automatic indexing
- Reference validation
- Version tracking

---

# 8. Alignment Module

Multiple aligners must be supported.

## STAR

Capabilities:

- 2-pass mode
- Chimeric alignment
- Gene counting

## HISAT2

Capabilities:

- Splice-aware mapping
- Transcriptome-aware alignment

Optional future support:

- minimap2
- Bowtie2

Deliverables:

- Sorted BAM
- BAM index
- Alignment statistics

---

# 9. Post-Alignment QC

Required tools:

- samtools
- Qualimap
- RSeQC
- Picard
- MultiQC

Metrics:

- Mapping rate
- Duplication rate
- Insert size
- Junction saturation
- Gene body coverage
- Strandness
- Coverage uniformity

---

# 10. Quantification Module

The workflow shall support multiple quantification strategies.

## Gene-level

- featureCounts
- HTSeq-count
- STAR GeneCounts

## Transcript-level

- Salmon

Optional future support:

- kallisto
- RSEM

Outputs:

- Raw counts
- TPM
- FPKM
- CPM

---

# 11. Fusion Detection

Mandatory:

STAR-Fusion

Deliverables:

- Fusion tables
- Candidate ranking
- QC metrics

Optional future support:

- Arriba

---

# 12. Alternative Splicing

Mandatory:

rMATS

Events:

- SE
- RI
- A5SS
- A3SS
- MXE

Outputs:

- Statistical tables
- Event summaries
- Visualizations

---

# 13. Differential Expression Analysis

## Metadata Driven Execution

The workflow shall automatically read sample_design.tsv.

Supported analyses:

- Two-group comparisons
- Multifactor designs
- Paired designs
- Batch correction models

Tools:

- DESeq2
- edgeR (optional)

Outputs:

- Differential expression tables
- Annotated results
- Statistical summaries

---

# 14. Functional Interpretation

Mandatory:

- ORA enrichments (GO BP/MF/CC; KEGG; Reactome)
- [optional] GSEA enrichments (MsigDB [human & mouse where applicable - HALLMARK, GO BP, GO MF, GO CC and KEGG] + custom defined GMT support )


Tools:

- clusterProfiler

Outputs:

- Tables
- Figures
- Interactive reports

---

# 15. Visualization Requirements

Mandatory visualizations:

- PCA
- UMAP
- Sample clustering
- Heatmaps
- Volcano plots
- MA plots
- Dispersion plots
- QC dashboards
- Fusion summaries
- Splicing summaries

Interactive reports preferred.

Technologies:

- RMarkdown
- Quarto
- HTML

---

# 16. Reporting

The system shall automatically generate:

## Executive Report

Audience:

- Principal Investigators
- Managers
- Collaborators

## Technical Report

Audience:

- Bioinformaticians
- Data Scientists
- Geneticians

## QC Report

Audience:

- Sequencing Facilities

## Differential Analysis Report

Audience:

- Researchers

---

# 17. Reproducibility Requirements

Mandatory:

- Immutable containers
- Version locking
- Checksums
- Pipeline provenance
- Environment capture

The same inputs must produce identical outputs.

---

# 18. Containerization

## Docker

Contractor shall provide:

- Versioned images
- Dockerfiles
- Registry publication

## Apptainer

Contractor shall provide:

- Prebuilt images
- Definition files

No external software installation shall be required.

---

# 19. HPC Compatibility

The delivered solution must operate on:

- SLURM clusters
- PBS clusters
- LSF clusters
- Shared filesystems

Support:

- Resource profiles
- Parallel execution
- Resume execution

---

# 20. Testing and Validation

Contractor must provide:

- Unit tests
- Integration tests
- Regression tests

Validation datasets:

- Small dataset
- Medium dataset
- Full production dataset

Acceptance tests must be documented.

---

# 21. Security and Compliance

Requirements:

- No internet access required during execution
- Reproducible environments
- Auditability
- Traceability

---

# 22. Repository Structure

A dedicated Git repository shall be delivered.

Minimum contents:

README.md
LICENSE
ROADMAP.md
CHANGELOG.md
CONTRIBUTING.md
CODE_OF_CONDUCT.md
USAGE.md
INSTALLATION.md
ARCHITECTURE.md
FAQ.md
TROUBLESHOOTING.md
RELEASE_PROCESS.md

Directories:

/modules
/workflows
/conf
/docs
/examples
/tests
/assets
/containers
/scripts

---

# 23. Documentation Requirements

User documentation:

- Installation
- Configuration
- Execution
- Interpretation

Developer documentation:

- Architecture
- Module creation
- CI/CD process

Administrator documentation:

- HPC deployment
- Container deployment

---

# 24. CI/CD Requirements

Preferred platform:

GitHub Actions

Capabilities:

- Build validation
- Container validation
- Automated testing
- Release automation

---

# 25. Training and Knowledge Transfer

Contractor shall provide:

- Installation guide
- User guide
- Developer guide
- Recorded demonstrations
- Example datasets

---

# 26. Acceptance Criteria

The project shall be considered accepted only if:

1. Workflow executes successfully from FASTQ to reports.
2. All modules pass validation tests.
3. Docker images operate correctly.
4. Apptainer images operate correctly.
5. HPC deployment is demonstrated.
6. Example datasets reproduce documented results.
7. Documentation is complete.
8. Repository is delivered.
9. Final reports are generated automatically.
10. Source code is transferred to the client.

---

# 27. Deliverables

Mandatory deliverables:

1. Complete Nextflow DSL2 pipeline.
2. Source code repository.
3. Docker images.
4. Apptainer images.
5. Validation datasets.
6. Example datasets.
7. Automated test suite.
8. User documentation.
9. Developer documentation.
10. Final acceptance report.
11. Training materials.
12. Release package.

---

# 28. Future Extensions

Architecture must allow future integration of:

- Single-cell RNA-seq
- Long-read RNA-seq
- Spatial transcriptomics
- Isoform discovery
- Multi-omics integration

---

END OF SPECIFICATION
