// clusterProfiler GSEA — rank-based enrichment over the full DE gene list using
// MSigDB collections (HALLMARK, GO BP/MF/CC, KEGG) for human/mouse, or a custom
// GMT. Optional stage. Delegates to bin/clusterprofiler_gsea.r.
process CLUSTERPROFILER_GSEA {
    tag   "${contrast.id}"
    label 'process_medium'

    input:
    tuple val(contrast), path(de_results)
    val   orgdb
    val   msigdb_species
    path  gmt          // 'NO_GMT' placeholder => use MSigDB collections

    output:
    tuple val(contrast), path("*.gsea_*.tsv"), emit: tables, optional: true
    tuple val(contrast), path("*.{pdf,png}"), emit: plots,  optional: true
    path "versions.yml", emit: versions

    script:
    def gmt_arg = gmt.name != 'NO_GMT' ? "--gmt ${gmt}" : ''
    """
    clusterprofiler_gsea.r \\
        --de ${de_results} \\
        --contrast_id ${contrast.id} \\
        --orgdb ${orgdb} \\
        --species '${msigdb_species}' \\
        --categories '${params.msigdb_categories}' \\
        ${gmt_arg}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioconductor-clusterprofiler: \$(Rscript -e 'cat(as.character(packageVersion("clusterProfiler")))' 2>/dev/null || echo NA)
    END_VERSIONS
    """

    stub:
    """
    printf 'ID\\tDescription\\tNES\\tp.adjust\\n' > ${contrast.id}.gsea_HALLMARK.tsv
    echo stub > ${contrast.id}.gsea_ridgeplot.pdf
    touch versions.yml
    """
}
