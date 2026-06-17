// DESeq2 — model-based differential expression for one contrast. The R script
// builds the design from sample_design.tsv (optionally adding blocking factors
// for multifactor / paired / batch-corrected models), fits the negative-binomial
// GLM, and emits the results table plus the SRS-mandated plots (PCA, MA,
// volcano, dispersion, sample-distance heatmap). Delegates to bin/deseq2.r.
process DESEQ2 {
    tag   "${contrast.id}"
    label 'process_medium'

    input:
    tuple val(contrast), path(counts), path(design)

    output:
    tuple val(contrast), path("*.deseq2_results.tsv"), emit: results
    tuple val(contrast), path("*.normalized_counts.tsv"), emit: normalized, optional: true
    tuple val(contrast), path("*.{pdf,png}"), emit: plots, optional: true
    path "*.deseq2_summary.txt", emit: summary, optional: true
    path "versions.yml", emit: versions

    script:
    def blocking = params.blocking_factors ? "--blocking ${params.blocking_factors}" : ''
    """
    deseq2.r \\
        --counts ${counts} \\
        --design ${design} \\
        --contrast_id ${contrast.id} \\
        --variable ${contrast.variable} \\
        --reference ${contrast.reference} \\
        --target ${contrast.target} \\
        --fdr ${params.de_fdr} \\
        --lfc ${params.de_lfc} \\
        --min_count ${params.de_min_count} \\
        ${blocking}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioconductor-deseq2: \$(Rscript -e 'cat(as.character(packageVersion("DESeq2")))' 2>/dev/null || echo NA)
    END_VERSIONS
    """

    stub:
    """
    printf 'gene_id\\tbaseMean\\tlog2FoldChange\\tpvalue\\tpadj\\n' > ${contrast.id}.deseq2_results.tsv
    printf 'gene1\\t100\\t1.5\\t0.001\\t0.01\\n' >> ${contrast.id}.deseq2_results.tsv
    printf 'gene_id\\ts1\\ts2\\ngene1\\t98\\t102\\n' > ${contrast.id}.normalized_counts.tsv
    echo "stub" > ${contrast.id}.pca.pdf
    echo "DE summary stub" > ${contrast.id}.deseq2_summary.txt
    touch versions.yml
    """
}
