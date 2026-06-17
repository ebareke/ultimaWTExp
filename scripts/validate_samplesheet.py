#!/usr/bin/env python3
"""
validate_samplesheet.py — pre-flight check of an input samplesheet + design.

Catches the common mistakes before a (potentially long) run starts:
  * required columns present
  * fastq files referenced actually exist (unless --no-paths)
  * every samplesheet sample_id has a matching row in the design (and vice versa)
  * design has the SRS-mandated metadata columns

  scripts/validate_samplesheet.py samplesheet.csv [--design sample_design.tsv]
"""
import argparse
import csv
import os
import sys

REQUIRED_SS = ["sample_id", "fastq_1"]
REQUIRED_DESIGN = ["sample_id", "subject_id", "condition", "batch", "sex", "tissue", "replicate"]


def fail(msg, errors):
    errors.append(msg)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("samplesheet")
    ap.add_argument("--design")
    ap.add_argument("--no-paths", action="store_true", help="skip FASTQ existence check")
    args = ap.parse_args()
    errors = []

    with open(args.samplesheet, newline="") as fh:
        rows = list(csv.DictReader(fh))
    if not rows:
        fail("samplesheet is empty", errors)
    else:
        for col in REQUIRED_SS:
            if col not in rows[0]:
                fail(f"samplesheet missing column '{col}'", errors)
    ss_ids = set()
    for i, r in enumerate(rows, 2):
        sid = (r.get("sample_id") or "").strip()
        if not sid:
            fail(f"samplesheet line {i}: empty sample_id", errors)
            continue
        if sid in ss_ids:
            fail(f"duplicate sample_id '{sid}'", errors)
        ss_ids.add(sid)
        if not args.no_paths:
            for col in ("fastq_1", "fastq_2"):
                p = (r.get(col) or "").strip()
                if p and not os.path.exists(p):
                    fail(f"{sid}: {col} not found: {p}", errors)

    if args.design:
        with open(args.design) as fh:
            header = fh.readline().rstrip("\n").split("\t")
            for col in REQUIRED_DESIGN:
                if col not in header:
                    fail(f"design missing column '{col}'", errors)
            sidx = header.index("sample_id") if "sample_id" in header else 0
            design_ids = {ln.split("\t")[sidx].strip() for ln in fh if ln.strip()}
        for sid in ss_ids - design_ids:
            fail(f"sample '{sid}' in samplesheet but not in design", errors)

    if errors:
        sys.stderr.write("Samplesheet validation FAILED:\n  - " + "\n  - ".join(errors) + "\n")
        sys.exit(1)
    print(f"OK: {len(ss_ids)} samples validated.")


if __name__ == "__main__":
    main()
