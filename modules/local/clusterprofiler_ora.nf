// clusterProfiler ORA — over-representation analysis of the significant DE gene
// set against GO (BP/MF/CC), KEGG and Reactome. Organism OrgDb / KEGG code come
// from conf/genomes.config. Delegates to bin/clusterprofiler_ora.r.
process CLUSTERPROFILER_ORA {
    tag   "${contrast.id}"
    label 'process_medium'

    input:
    tuple val(contrast), path(de_results)
    val   orgdb
    val   kegg_code

    output:
    tuple val(contrast), path("*.ora_*.tsv"), emit: tables, optional: true
    tuple val(contrast), path("*.{pdf,png}"), emit: plots,  optional: true
    path "versions.yml", emit: versions

    script:
    """
    clusterprofiler_ora.r \\
        --de ${de_results} \\
        --contrast_id ${contrast.id} \\
        --orgdb ${orgdb} \\
        --kegg ${kegg_code} \\
        --databases '${params.enrichment_dbs}' \\
        --fdr ${params.ora_fdr} \\
        --de_fdr ${params.de_fdr}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioconductor-clusterprofiler: \$(Rscript -e 'cat(as.character(packageVersion("clusterProfiler")))' 2>/dev/null || echo NA)
    END_VERSIONS
    """

    stub:
    """
    printf 'ID\\tDescription\\tpvalue\\tp.adjust\\n' > ${contrast.id}.ora_GO_BP.tsv
    echo stub > ${contrast.id}.ora_dotplot.pdf
    touch versions.yml
    """
}
