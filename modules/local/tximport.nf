// tximport — summarise Salmon transcript estimates to gene level (length-scaled
// TPM), producing gene counts + TPM matrices suitable for DESeq2. Delegates to
// bin/run_tximport.r.
process TXIMPORT {
    tag   "salmon"
    label 'process_low'

    input:
    path  ("salmon/*")
    path  tx2gene

    output:
    path "salmon.gene_counts.tsv",        emit: gene_counts
    path "salmon.gene_tpm.tsv",           emit: gene_tpm
    path "salmon.transcript_tpm.tsv",     emit: transcript_tpm
    path "versions.yml", emit: versions

    script:
    """
    run_tximport.r salmon ${tx2gene} salmon

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioconductor-tximport: \$(Rscript -e 'cat(as.character(packageVersion("tximport")))' 2>/dev/null || echo NA)
    END_VERSIONS
    """

    stub:
    """
    printf 'gene_id\\ts1\\ts2\\ngene1\\t40\\t60\\n' > salmon.gene_counts.tsv
    printf 'gene_id\\ts1\\ts2\\ngene1\\t10\\t12\\n' > salmon.gene_tpm.tsv
    printf 'tx_id\\ts1\\ts2\\ntx1\\t10\\t12\\n'     > salmon.transcript_tpm.tsv
    touch versions.yml
    """
}
