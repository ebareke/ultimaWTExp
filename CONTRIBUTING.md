# Contributing

Issues and pull requests are welcome.

## Getting started

```bash
git clone https://github.com/ebareke/ultimaWTExp.git
cd ultimaWTExp
export NXF_SYNTAX_PARSER=v1

bash tests/test_pipeline.sh                  # tool-free assertion suite
python3 examples/scripts/make_synthetic.py
nextflow run main.nf -profile test -stub-run # full topology, no tools
```

For a real run, build the toolchain with `mamba env create -f environment.yml`
or use the container (`docker build -t ultimawtexp:1.0.0 .`).

## Ground rules

- **Every process ships a `stub:` block.** It must create the declared outputs
  so `nextflow -stub-run` exercises the whole graph on a bare runner. New
  behaviour comes with a stub and, where possible, an assertion in
  `tests/test_pipeline.sh`.
- **Modules wrap one tool.** Keep `publishDir` and tool flags in
  `conf/modules.config`, resources in `conf/base.config` — not hard-coded in the
  module. Emit a `versions.yml`.
- **No silent fallbacks.** A step runs the real tool or fails with a clear
  error; optional stages are explicitly logged and skipped (fusion without a
  CTAT library, enrichment for `--organism custom`), never faked.
- **Classic DSL2 syntax.** Don't add `def` functions/variables to `conf/*.config`
  (the strict parser rejects them); keep helper logic in workflow/subworkflow
  Groovy or `bin/` scripts.
- **Reproducibility first.** Pin tool versions in `environment.yml`; don't fetch
  data at runtime.

## Where contributions help most

- **New tools / stages** (`modules/local/`, wired into a subworkflow) — e.g.
  Arriba, kallisto, RSEM, salmon-alevin for the roadmap items.
- **Real-data robustness** — odd contig naming, gzipped references, unusual
  strandedness, multi-lane samples make great regression fixtures.
- **Report polish** (`assets/report/*.qmd`) and MultiQC config.
- **Executor/cloud profiles** (`nextflow.config`) for more schedulers.

## Pull-request checklist

- [ ] `bash tests/test_pipeline.sh` passes; new behaviour has assertions.
- [ ] `nextflow run main.nf -profile test -stub-run` completes.
- [ ] `nextflow config -profile test` resolves; `python3 -m py_compile bin/*.py` clean.
- [ ] User-facing changes reflected in `USAGE.md` and `CHANGELOG.md`.
- [ ] New module has a `stub:` block and emits `versions.yml`.

## Commit style

Short imperative subject lines ("Add Arriba fusion module", "Fix Salmon libType
for SE"). Reference issues where relevant.

## Maintainers

- Eric Bareke — <bareke.eric@gmail.com>
- Ethan M. — <eb.bioinfo+ethan@pm.me>
- Conrad B. — <eb.bioinfo+conrad@pm.me>
