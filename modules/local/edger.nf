// edgeR — optional alternative DE engine (quasi-likelihood F-test) for the same
// contrast, useful as a cross-check on DESeq2 calls. Delegates to bin/edger.r.
process EDGER {
    tag   "${contrast.id}"
    label 'process_medium'

    input:
    tuple val(contrast), path(counts), path(design)

    output:
    tuple val(contrast), path("*.edger_results.tsv"), emit: results
    tuple val(contrast), path("*.{pdf,png}"), emit: plots, optional: true
    path "versions.yml", emit: versions

    script:
    def blocking = params.blocking_factors ? "--blocking ${params.blocking_factors}" : ''
    """
    edger.r \\
        --counts ${counts} \\
        --design ${design} \\
        --contrast_id ${contrast.id} \\
        --variable ${contrast.variable} \\
        --reference ${contrast.reference} \\
        --target ${contrast.target} \\
        --fdr ${params.de_fdr} \\
        --min_count ${params.de_min_count} \\
        ${blocking}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioconductor-edger: \$(Rscript -e 'cat(as.character(packageVersion("edgeR")))' 2>/dev/null || echo NA)
    END_VERSIONS
    """

    stub:
    """
    printf 'gene_id\\tlogFC\\tlogCPM\\tPValue\\tFDR\\ngene1\\t1.4\\t5\\t0.002\\t0.02\\n' > ${contrast.id}.edger_results.tsv
    echo stub > ${contrast.id}.mds.pdf
    touch versions.yml
    """
}
