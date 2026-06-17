// merge_counts — combine per-sample gene counts (featureCounts or HTSeq) into
// a single matrix, and derive the normalised matrices the SRS requires:
// raw counts, TPM, FPKM and CPM. Gene lengths come from the featureCounts
// Length column (or the GTF for HTSeq). Delegates to bin/merge_counts.py.
process MERGE_COUNTS {
    tag   "${counter}"
    label 'process_low'

    input:
    path  count_files
    val   counter        // 'featurecounts' | 'htseq'
    path  gtf

    output:
    path "counts.raw.tsv", emit: raw
    path "counts.tpm.tsv", emit: tpm
    path "counts.fpkm.tsv", emit: fpkm
    path "counts.cpm.tsv", emit: cpm
    path "versions.yml", emit: versions

    script:
    """
    merge_counts.py --counter ${counter} --gtf ${gtf} --out-prefix counts ${count_files}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //')
        pandas: \$(python3 -c 'import pandas; print(pandas.__version__)' 2>/dev/null || echo NA)
    END_VERSIONS
    """

    stub:
    """
    for m in raw tpm fpkm cpm; do printf 'gene_id\\ts1\\ts2\\ngene1\\t10\\t20\\ngene2\\t5\\t8\\n' > counts.\$m.tsv; done
    touch versions.yml
    """
}
