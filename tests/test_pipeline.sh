#!/usr/bin/env bash
# ===========================================================================
# tests/test_pipeline.sh — tool-free unit / contract tests for ultimaWTExp.
#
# Runs without Nextflow or any bioinformatics tool (only bash + python3), so it
# is fast and CI-portable. It checks:
#   * structural invariants (every module has a stub; mandated docs/dirs exist)
#   * the synthetic-data generator produces the mandated design columns
#   * the count-merging maths (raw/TPM/FPKM/CPM) on a known fixture
#   * the software-version collator merges multiple blocks
#
# The full end-to-end topology is verified separately by `nextflow -stub-run`
# (see the CI 'stub' job / `make stub`).
# ===========================================================================
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cd "$ROOT"

PASS=0; FAIL=0
ok()  { printf '  \033[32mok\033[0m   %s\n' "$1"; PASS=$((PASS+1)); }
bad() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }
assert_file()     { [ -f "$1" ] && ok "exists: $1" || bad "missing: $1"; }
assert_contains() { case "$(cat "$2" 2>/dev/null)" in *"$1"*) ok "$3" ;; *) bad "$3" ;; esac; }

echo "== structural invariants =="
# Every process module must ship a stub: block (so -stub-run works everywhere).
missing_stub=0
for f in modules/local/*.nf; do
    if ! grep -q 'stub:' "$f"; then echo "    no stub: $f"; missing_stub=$((missing_stub+1)); fi
done
[ "$missing_stub" -eq 0 ] && ok "all modules have a stub block" || bad "$missing_stub module(s) lack a stub"

# Mandated repository documents (SRS §22).
for d in README.md LICENSE ROADMAP.md CHANGELOG.md CONTRIBUTING.md \
         CODE_OF_CONDUCT.md USAGE.md INSTALLATION.md ARCHITECTURE.md \
         FAQ.md TROUBLESHOOTING.md RELEASE_PROCESS.md docs/index.html; do
    assert_file "$d"
done

# Mandated directories (SRS §22).
for dir in modules workflows conf docs examples tests assets containers scripts; do
    [ -d "$dir" ] && ok "dir: $dir" || bad "missing dir: $dir"
done

echo "== synthetic dataset / mandated design columns =="
python3 examples/scripts/make_synthetic.py >/dev/null
assert_file examples/data/genome.fa
assert_file examples/data/genes.gtf
assert_file examples/data/samplesheet.csv
header="$(head -n1 examples/data/sample_design.tsv)"
for col in sample_id subject_id condition batch sex tissue replicate; do
    case "$header" in *"$col"*) ok "design has '$col'" ;; *) bad "design missing '$col'" ;; esac
done
n_genes="$(awk -F'\t' '$3=="gene"' examples/data/genes.gtf | wc -l | tr -d ' ')"
[ "$n_genes" -ge 2 ] && ok "GTF has >=2 genes ($n_genes)" || bad "GTF gene count $n_genes"
n_samples="$(($(wc -l < examples/data/samplesheet.csv) - 1))"
[ "$n_samples" -eq 6 ] && ok "samplesheet has 6 samples" || bad "samplesheet has $n_samples samples"

echo "== count-merge maths (featureCounts fixture) =="
# Two samples, two genes, known lengths (1000 and 2000 bp) and counts.
mk_fc() {  # $1=sample $2=count_geneA $3=count_geneB
    printf '# featureCounts\nGeneid\tChr\tStart\tEnd\tStrand\tLength\t%s\n' "$1" > "$TMP/$1.featureCounts.txt"
    printf 'geneA\tchr1\t1\t1000\t+\t1000\t%s\n' "$2" >> "$TMP/$1.featureCounts.txt"
    printf 'geneB\tchr1\t2000\t3999\t+\t2000\t%s\n' "$3" >> "$TMP/$1.featureCounts.txt"
}
mk_fc s1 1000 1000
mk_fc s2 0 2000
( cd "$TMP" && python3 "$ROOT/bin/merge_counts.py" --counter featurecounts \
    --gtf "$ROOT/examples/data/genes.gtf" --out-prefix m \
    s1.featureCounts.txt s2.featureCounts.txt >/dev/null 2>&1 )
assert_file "$TMP/m.raw.tsv"
assert_file "$TMP/m.tpm.tsv"; assert_file "$TMP/m.fpkm.tsv"; assert_file "$TMP/m.cpm.tsv"
# s1: both genes get equal RPK (1000/1kb=1 ; 1000/2kb=0.5) -> TPM 666667/333333.
tpm_a="$(awk -F'\t' '$1=="geneA"{print $2}' "$TMP/m.tpm.tsv")"
case "$tpm_a" in 666666*|666667*) ok "TPM(geneA,s1) ~ 666667 ($tpm_a)" ;; *) bad "TPM(geneA,s1)=$tpm_a" ;; esac
# CPM(geneA,s1): 1000 / (2000/1e6) = 500000.
cpm_a="$(awk -F'\t' '$1=="geneA"{print $2}' "$TMP/m.cpm.tsv")"
case "$cpm_a" in 500000*) ok "CPM(geneA,s1) = 500000 ($cpm_a)" ;; *) bad "CPM(geneA,s1)=$cpm_a" ;; esac

echo "== software-version collator =="
printf '"PROC_A":\n    tool1: 1.0\n' > "$TMP/v1.yml"
printf '"PROC_B":\n    tool2: 2.0\n' > "$TMP/v2.yml"
python3 bin/dump_versions.py "$TMP/v1.yml" "$TMP/v2.yml" > "$TMP/merged.yml"
assert_contains 'tool1: 1.0' "$TMP/merged.yml" "collator keeps PROC_A:tool1"
assert_contains 'tool2: 2.0' "$TMP/merged.yml" "collator keeps PROC_B:tool2"
assert_contains 'Workflow:'  "$TMP/merged.yml" "collator adds Workflow block"

echo ""
echo "----------------------------------------"
printf 'Passed: %d   Failed: %d\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] && { echo "ALL TESTS PASSED"; exit 0; } || { echo "TESTS FAILED"; exit 1; }
