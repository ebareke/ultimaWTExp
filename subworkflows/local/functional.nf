/*
 * functional — biological interpretation of DE results. ORA (GO BP/MF/CC, KEGG,
 * Reactome) over the significant gene set, and optional GSEA over the ranked
 * list (MSigDB collections or a custom GMT). Organism annotation packages come
 * from conf/genomes.config; an unmapped --organism custom run skips ID-based
 * enrichment unless a GMT is supplied.
 */

include { CLUSTERPROFILER_ORA  } from '../../modules/local/clusterprofiler_ora.nf'
include { CLUSTERPROFILER_GSEA } from '../../modules/local/clusterprofiler_gsea.nf'

workflow FUNCTIONAL {

    take:
    ch_de_results     // tuple(contrast, de_results.tsv)

    main:
    ch_versions = Channel.empty()

    def org      = params.organisms[params.organism]
    def orgdb    = org?.orgdb ?: 'NA'
    def kegg     = org?.kegg_code ?: 'NA'
    def species  = org?.msigdb_species ?: 'NA'

    // ---- ORA -------------------------------------------------------------
    if (orgdb != 'NA') {
        CLUSTERPROFILER_ORA( ch_de_results, orgdb, kegg )
        ch_versions = ch_versions.mix( CLUSTERPROFILER_ORA.out.versions.first() )
    } else {
        log.warn "ORA skipped: no OrgDb for --organism ${params.organism}."
    }

    // ---- GSEA (optional) -------------------------------------------------
    if (params.run_gsea && (orgdb != 'NA' || params.gsea_gmt)) {
        def gmt = params.gsea_gmt ? file(params.gsea_gmt, checkIfExists: true)
                                  : file("${projectDir}/assets/NO_GMT")
        CLUSTERPROFILER_GSEA( ch_de_results, orgdb, species, gmt )
        ch_versions = ch_versions.mix( CLUSTERPROFILER_GSEA.out.versions.first() )
    }

    emit:
    versions = ch_versions
}
