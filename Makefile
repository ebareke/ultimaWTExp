# ultimaWTExp — build & test automation
#
#   make help        list targets
#   make test        tool-free assertion suite
#   make stub        full topology stub-run on the synthetic dataset
#   make example     generate the synthetic dataset
#   make docker      build the Docker image
#   make apptainer   build the Apptainer .sif from the local Docker image
#   make clean       remove generated outputs

VERSION  := 1.0.0
IMAGE    := ultimawtexp
TAG      := $(VERSION)
SHELL    := /bin/bash
export NXF_SYNTAX_PARSER := v1

.PHONY: help test stub example docker apptainer lint clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n",$$1,$$2}'

example: ## Generate the synthetic example dataset
	python3 examples/scripts/make_synthetic.py

test: ## Run the tool-free assertion suite
	bash tests/test_pipeline.sh

stub: example ## Stub-run the full pipeline (no bioinformatics tools needed)
	nextflow run main.nf -profile test -stub-run --outdir stub_results

docker: ## Build the Docker image
	docker build -t $(IMAGE):$(TAG) -t $(IMAGE):latest .

apptainer: ## Build the Apptainer .sif from the local Docker image
	apptainer build $(IMAGE).sif docker-daemon://$(IMAGE):$(TAG)

lint: ## Validate config + byte-compile helper scripts
	nextflow config -profile test >/dev/null && echo "config OK"
	python3 -m py_compile bin/*.py examples/scripts/*.py && echo "python OK"

clean: ## Remove generated outputs
	rm -rf results stub_results ci_results work .nextflow* *.sif \
	       examples/data/*.fastq.gz examples/data/genome.fa examples/data/genes.gtf \
	       examples/data/samplesheet.csv examples/data/sample_design.tsv \
	       cfg_out.txt stub_out.txt config_err.txt bin/__pycache__ \
	       examples/scripts/__pycache__
