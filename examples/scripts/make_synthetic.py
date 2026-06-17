#!/usr/bin/env python3
"""
make_synthetic.py — deterministic tiny RNA-seq dataset for CI / smoke tests.

Writes into examples/data/:
  * genome.fa          one ~12 kb contig (chr1) with 3 "genes"
  * genes.gtf          gene/transcript/exon annotation for those 3 genes
  * <sample>_R1.fastq.gz / _R2.fastq.gz   6 paired-end samples
  * samplesheet.csv    sample_id,fastq_1,fastq_2,strandedness
  * sample_design.tsv  the mandated metadata (drives DE / splicing)

Two conditions (CTRL, TREAT) x 3 replicates. TREAT up-regulates geneB and
down-regulates geneC by sampling more/fewer reads, so a real end-to-end run
recovers a couple of DE genes. Reproducible: fixed RNG seed, so the same inputs
always yield the same files (a reproducibility-suite fixture).

Paths in the samplesheet are written relative to the repository root, so launch
Nextflow from there (`nextflow run main.nf -profile test`).
"""
import gzip
import os
import random

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.normpath(os.path.join(HERE, "..", "data"))
REL  = "examples/data"
random.seed(42)

BASES = "ACGT"
CONTIG = "chr1"
READLEN = 75

# (gene_id, gene_name, start, end, strand) — 1-based inclusive.
GENES = [
    ("geneA", "HOUSEKEEP1", 1000, 2200, "+"),
    ("geneB", "RESPONDER_UP", 4000, 5200, "+"),
    ("geneC", "RESPONDER_DN", 8000, 9200, "-"),
]
CONTIG_LEN = 12000


def rand_seq(n):
    return "".join(random.choice(BASES) for _ in range(n))


def revcomp(s):
    return s.translate(str.maketrans("ACGT", "TGCA"))[::-1]


def write_fasta(genome):
    with open(os.path.join(DATA, "genome.fa"), "w") as fh:
        fh.write(f">{CONTIG}\n")
        for i in range(0, len(genome), 60):
            fh.write(genome[i:i + 60] + "\n")


def write_gtf():
    with open(os.path.join(DATA, "genes.gtf"), "w") as fh:
        for gid, gname, s, e, strand in GENES:
            attr = f'gene_id "{gid}"; gene_name "{gname}"; gene_biotype "protein_coding";'
            tattr = f'gene_id "{gid}"; transcript_id "{gid}.1"; gene_name "{gname}";'
            fh.write(f"{CONTIG}\tsynthetic\tgene\t{s}\t{e}\t.\t{strand}\t.\t{attr}\n")
            fh.write(f"{CONTIG}\tsynthetic\ttranscript\t{s}\t{e}\t.\t{strand}\t.\t{tattr}\n")
            # two exons per gene (so splicing tools have something to chew on)
            mid = (s + e) // 2
            fh.write(f"{CONTIG}\tsynthetic\texon\t{s}\t{mid-50}\t.\t{strand}\t.\t{tattr} exon_number \"1\";\n")
            fh.write(f"{CONTIG}\tsynthetic\texon\t{mid+50}\t{e}\t.\t{strand}\t.\t{tattr} exon_number \"2\";\n")


def fastq_records(genome, gene, n_pairs, sid):
    gid, _, s, e, strand = gene
    body = genome[s - 1:e]
    r1, r2 = [], []
    for i in range(n_pairs):
        pos = random.randint(0, max(0, len(body) - 300))
        frag = body[pos:pos + 250]
        if len(frag) < READLEN + 20:
            frag = (frag + rand_seq(300))[:300]
        read1 = frag[:READLEN]
        read2 = revcomp(frag[-READLEN:])
        qual = "I" * READLEN
        name = f"@{sid}:{gid}:{i}/{{m}}"
        r1.append(f"{name.format(m=1)}\n{read1}\n+\n{qual}\n")
        r2.append(f"{name.format(m=2)}\n{read2}\n+\n{qual}\n")
    return r1, r2


def write_sample(genome, sid, condition):
    # Expression program: TREAT up-regulates geneB, down-regulates geneC.
    depth = {"geneA": 200, "geneB": 200, "geneC": 200}
    if condition == "TREAT":
        depth["geneB"] = 600
        depth["geneC"] = 60
    r1_all, r2_all = [], []
    for gene in GENES:
        r1, r2 = fastq_records(genome, gene, depth[gene[0]], sid)
        r1_all += r1
        r2_all += r2
    random.shuffle(r1_all)  # not strictly paired-order critical for a smoke test
    with gzip.open(os.path.join(DATA, f"{sid}_R1.fastq.gz"), "wt") as fh:
        fh.write("".join(r1_all))
    with gzip.open(os.path.join(DATA, f"{sid}_R2.fastq.gz"), "wt") as fh:
        fh.write("".join(r2_all))


def main():
    os.makedirs(DATA, exist_ok=True)

    # Build the contig: random backbone with the gene bodies inserted.
    genome = list(rand_seq(CONTIG_LEN))
    for gid, _, s, e, _ in GENES:
        gene_seq = rand_seq(e - s + 1)
        genome[s - 1:e] = list(gene_seq)
    genome = "".join(genome)

    write_fasta(genome)
    write_gtf()

    samples = [
        ("ctrl_rep1", "CTRL"), ("ctrl_rep2", "CTRL"), ("ctrl_rep3", "CTRL"),
        ("treat_rep1", "TREAT"), ("treat_rep2", "TREAT"), ("treat_rep3", "TREAT"),
    ]

    with open(os.path.join(DATA, "samplesheet.csv"), "w") as ss, \
         open(os.path.join(DATA, "sample_design.tsv"), "w") as ds:
        ss.write("sample_id,fastq_1,fastq_2,strandedness\n")
        ds.write("sample_id\tsubject_id\tcondition\tbatch\tsex\ttissue\treplicate\n")
        for i, (sid, cond) in enumerate(samples, start=1):
            write_sample(genome, sid, cond)
            ss.write(f"{sid},{REL}/{sid}_R1.fastq.gz,{REL}/{sid}_R2.fastq.gz,reverse\n")
            rep = (i - 1) % 3 + 1
            batch = "B1" if i % 2 else "B2"
            sex = "F" if i % 2 else "M"
            ds.write(f"{sid}\tsubj{rep}\t{cond}\t{batch}\t{sex}\tliver\t{rep}\n")

    print(f"[make_synthetic] wrote {len(samples)} samples + reference to {DATA}")


if __name__ == "__main__":
    main()
