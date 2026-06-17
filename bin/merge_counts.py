#!/usr/bin/env python3
"""
merge_counts.py — combine per-sample gene counts into a single matrix and derive
the normalised matrices the SRS requires (raw, TPM, FPKM, CPM).

Supports three counters:
  * featurecounts : per-sample *.featureCounts.txt (Geneid..Length..<count>)
  * htseq         : per-sample *.htseq.txt (gene<TAB>count, trailing __* rows)
  * star          : per-sample *.ReadsPerGene.out.tab (unstranded column)

Gene lengths come from the featureCounts Length column, else from the GTF
(union exon length per gene). Normalisations:
  TPM  : length-normalise then depth-normalise to 1e6
  FPKM : depth-normalise to 1e6 then length-normalise (per kb)
  CPM  : depth-normalise to 1e6 (no length term)
"""
import argparse
import os
import re
import sys
from collections import defaultdict


def gene_lengths_from_gtf(gtf):
    """Union exon length per gene_id (merged intervals)."""
    exons = defaultdict(list)
    gene_re = re.compile(r'gene_id "([^"]+)"')
    with open(gtf) as fh:
        for line in fh:
            if line.startswith('#'):
                continue
            f = line.rstrip('\n').split('\t')
            if len(f) < 9 or f[2] != 'exon':
                continue
            m = gene_re.search(f[8])
            if not m:
                continue
            exons[m.group(1)].append((int(f[3]), int(f[4])))
    lengths = {}
    for gid, ivs in exons.items():
        ivs.sort()
        total, cur_s, cur_e = 0, None, None
        for s, e in ivs:
            if cur_s is None:
                cur_s, cur_e = s, e
            elif s <= cur_e + 1:
                cur_e = max(cur_e, e)
            else:
                total += cur_e - cur_s + 1
                cur_s, cur_e = s, e
        if cur_s is not None:
            total += cur_e - cur_s + 1
        lengths[gid] = total
    return lengths


def sample_name(path, suffixes):
    base = os.path.basename(path)
    for suf in suffixes:
        if base.endswith(suf):
            return base[: -len(suf)]
    return base


def read_featurecounts(path):
    counts, length = {}, {}
    with open(path) as fh:
        for line in fh:
            if line.startswith('#') or line.startswith('Geneid'):
                continue
            f = line.rstrip('\n').split('\t')
            counts[f[0]] = float(f[-1])
            length[f[0]] = int(f[5])
    return counts, length


def read_htseq(path):
    counts = {}
    with open(path) as fh:
        for line in fh:
            f = line.rstrip('\n').split('\t')
            if len(f) < 2 or f[0].startswith('__'):
                continue
            counts[f[0]] = float(f[1])
    return counts, {}


def read_star(path):
    counts = {}
    with open(path) as fh:
        for line in fh:
            f = line.rstrip('\n').split('\t')
            if len(f) < 4 or f[0].startswith('N_'):
                continue
            counts[f[0]] = float(f[1])  # column 2 = unstranded
    return counts, {}


READERS = {
    'featurecounts': (read_featurecounts, ['.featureCounts.txt']),
    'htseq':         (read_htseq,         ['.htseq.txt']),
    'star':          (read_star,          ['.ReadsPerGene.out.tab']),
}


def write_matrix(path, genes, samples, data):
    with open(path, 'w') as out:
        out.write('gene_id\t' + '\t'.join(samples) + '\n')
        for g in genes:
            row = '\t'.join('{:.4f}'.format(data[s].get(g, 0.0)).rstrip('0').rstrip('.')
                            for s in samples)
            out.write(g + '\t' + row + '\n')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--counter', required=True, choices=list(READERS))
    ap.add_argument('--gtf', required=True)
    ap.add_argument('--out-prefix', default='counts')
    ap.add_argument('files', nargs='+')
    args = ap.parse_args()

    reader, suffixes = READERS[args.counter]
    raw, lengths = {}, {}
    samples = []
    for path in args.files:
        s = sample_name(path, suffixes)
        samples.append(s)
        c, l = reader(path)
        raw[s] = c
        for gid, ln in l.items():
            lengths.setdefault(gid, ln)

    genes = sorted({g for s in samples for g in raw[s]})
    samples = sorted(samples)

    if not lengths:
        lengths = gene_lengths_from_gtf(args.gtf)
    # Guard against missing / zero lengths.
    for g in genes:
        if lengths.get(g, 0) <= 0:
            lengths[g] = 1

    # Library sizes.
    libsize = {s: sum(raw[s].get(g, 0.0) for g in genes) or 1.0 for s in samples}

    tpm, fpkm, cpm = ({s: {} for s in samples} for _ in range(3))
    for s in samples:
        rpk = {g: raw[s].get(g, 0.0) / (lengths[g] / 1000.0) for g in genes}
        rpk_sum = sum(rpk.values()) or 1.0
        for g in genes:
            tpm[s][g] = rpk[g] / rpk_sum * 1e6
            fpkm[s][g] = raw[s].get(g, 0.0) / (libsize[s] / 1e6) / (lengths[g] / 1000.0)
            cpm[s][g] = raw[s].get(g, 0.0) / (libsize[s] / 1e6)

    write_matrix(f'{args.out_prefix}.raw.tsv', genes, samples,
                 {s: {g: raw[s].get(g, 0.0) for g in genes} for s in samples})
    write_matrix(f'{args.out_prefix}.tpm.tsv', genes, samples, tpm)
    write_matrix(f'{args.out_prefix}.fpkm.tsv', genes, samples, fpkm)
    write_matrix(f'{args.out_prefix}.cpm.tsv', genes, samples, cpm)
    sys.stderr.write(f'[merge_counts] {len(genes)} genes x {len(samples)} samples\n')


if __name__ == '__main__':
    main()
