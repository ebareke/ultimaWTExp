# Installation

ultimaWTExp needs only two things on the host: **Nextflow** and a **container
engine**. Every bioinformatics tool lives inside the provided image, so nothing
else is installed system-wide.

## 1. Requirements

| Component | Version | Notes |
|---|---|---|
| Java | 17–24 | Required by Nextflow |
| Nextflow | ≥ 23.04 | DSL2 |
| Container engine | Docker **or** Apptainer/Singularity | Apptainer for HPC |
| (optional) Conda/Mamba | — | Alternative to containers |

> **Nextflow language parser.** This pipeline uses the classic DSL2 syntax.
> On Nextflow ≥ 25 (which defaults to the new strict parser) set
> `export NXF_SYNTAX_PARSER=v1`. CI and the helper scripts set this for you.

## 2. Install Nextflow

```bash
curl -s https://get.nextflow.io | bash
sudo mv nextflow /usr/local/bin/    # or anywhere on $PATH
nextflow -version
```

## 3. Get the pipeline

```bash
# Option A — let Nextflow pull it
nextflow run ebareke/ultimaWTExp --help

# Option B — clone (for development / offline HPC)
git clone https://github.com/ebareke/ultimaWTExp.git
cd ultimaWTExp
```

## 4. Get the container (one-time)

### Docker
```bash
docker pull ebareke/ultimawtexp:1.0.0          # Docker Hub (default image)
# GHCR mirror: docker pull ghcr.io/ebareke/ultimawtexp:1.0.0
# or build locally:
docker build -t ultimawtexp:1.0.0 .
```

### Apptainer / Singularity (HPC)
```bash
# From the published OCI artifact (recommended)
apptainer pull oras://ghcr.io/ebareke/ultimawtexp-apptainer:1.0.0
# or build from the definition / a local Docker image (see containers/README.md)
```

Point a shared cache at the SIF so cluster nodes reuse it:
```bash
export NXF_SINGULARITY_CACHEDIR=/shared/apptainer_cache
```

### Conda (no containers)
```bash
mamba env create -f environment.yml
mamba activate ultimawtexp
nextflow run main.nf -profile conda ...
```

## 5. Stage reference data

ultimaWTExp **never downloads or redistributes genomes** (offline, no
licensing surprises). Provide your own:

| Input | Flag | Notes |
|---|---|---|
| Genome FASTA | `--fasta` | `.fa` / `.fa.gz` |
| Gene annotation | `--gtf` (or `--gff`) | GFF is converted with gffread |
| (optional) prebuilt indices | `--star_index` / `--hisat2_index` / `--salmon_index` | else built once and reused |
| (optional) RSeQC BED12 | `--gene_bed` | else derived from the GTF |
| (optional, fusion) CTAT library | `--star_fusion_ref` | required for `--run_fusion` |

For human/mouse/rat, set `--organism` so the enrichment stage can map IDs to
GO/KEGG/Reactome automatically.

## 6. Verify the install

```bash
# Tool-free assertion suite
bash tests/test_pipeline.sh

# Full topology, no tools needed
python3 examples/scripts/make_synthetic.py
NXF_SYNTAX_PARSER=v1 nextflow run main.nf -profile test -stub-run

# Real synthetic end-to-end (needs a container engine)
bash examples/run_example.sh
```

See [USAGE.md](USAGE.md) to run on your own data and
[TROUBLESHOOTING.md](TROUBLESHOOTING.md) if a step fails.
