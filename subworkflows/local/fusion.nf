/*
 * fusion — gene-fusion detection with STAR-Fusion from STAR chimeric junctions.
 * Requires a CTAT genome library (--star_fusion_ref); skipped with a warning if
 * absent so the pipeline still completes on environments without it.
 */

include { STAR_FUSION } from '../../modules/local/star_fusion.nf'

workflow FUSION {

    take:
    ch_chimeric       // tuple(meta, Chimeric.out.junction)

    main:
    ch_versions = Channel.empty()
    ch_fusions  = Channel.empty()

    if (params.star_fusion_ref) {
        def ctat = file(params.star_fusion_ref, checkIfExists: true)
        STAR_FUSION( ch_chimeric, ctat )
        ch_fusions  = STAR_FUSION.out.fusions
        ch_versions = ch_versions.mix( STAR_FUSION.out.versions.first() )
    } else {
        log.warn "Fusion detection skipped: --star_fusion_ref (CTAT library) not provided."
    }

    emit:
    fusions  = ch_fusions
    versions = ch_versions
}
