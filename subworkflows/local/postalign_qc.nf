/*
 * postalign_qc — the alignment-level QC battery the SRS mandates: duplication
 * (Picard MarkDuplicates + dupRadar), coverage uniformity & RNA composition
 * (Picard CollectRnaSeqMetrics, Qualimap), strandedness / junction saturation /
 * gene-body coverage / read distribution (RSeQC), and library complexity
 * (preseq). Every output is funnelled to MultiQC.
 */

include { PICARD_MARKDUPLICATES } from '../../modules/local/picard_markduplicates.nf'
include { PICARD_RNASEQMETRICS  } from '../../modules/local/picard_rnaseqmetrics.nf'
include { QUALIMAP_RNASEQ       } from '../../modules/local/qualimap_rnaseq.nf'
include { RSEQC                 } from '../../modules/local/rseqc.nf'
include { PRESEQ                } from '../../modules/local/preseq.nf'
include { DUPRADAR              } from '../../modules/local/dupradar.nf'

workflow POSTALIGN_QC {

    take:
    ch_bam_bai        // tuple(meta, bam, bai)
    ch_gtf
    ch_gene_bed

    main:
    ch_versions = Channel.empty()
    ch_multiqc  = Channel.empty()

    if (!params.skip_picard) {
        PICARD_MARKDUPLICATES( ch_bam_bai )
        PICARD_RNASEQMETRICS( ch_bam_bai, ch_gtf )
        ch_multiqc  = ch_multiqc
            .mix( PICARD_MARKDUPLICATES.out.metrics.map { meta, f -> f } )
            .mix( PICARD_RNASEQMETRICS.out.metrics.map  { meta, f -> f } )
        ch_versions = ch_versions.mix( PICARD_MARKDUPLICATES.out.versions.first() )
    }

    if (!params.skip_qualimap) {
        QUALIMAP_RNASEQ( ch_bam_bai, ch_gtf )
        ch_multiqc  = ch_multiqc.mix( QUALIMAP_RNASEQ.out.results.map { meta, d -> d } )
        ch_versions = ch_versions.mix( QUALIMAP_RNASEQ.out.versions.first() )
    }

    if (!params.skip_rseqc) {
        RSEQC( ch_bam_bai, ch_gene_bed )
        ch_multiqc  = ch_multiqc.mix( RSEQC.out.results.map { meta, f -> f } )
        ch_versions = ch_versions.mix( RSEQC.out.versions.first() )
    }

    if (!params.skip_preseq) {
        PRESEQ( ch_bam_bai )
        ch_multiqc  = ch_multiqc.mix( PRESEQ.out.ccurve.map { meta, f -> f } )
        ch_versions = ch_versions.mix( PRESEQ.out.versions.first() )
    }

    if (!params.skip_dupradar) {
        DUPRADAR( ch_bam_bai, ch_gtf )
        ch_multiqc  = ch_multiqc.mix( DUPRADAR.out.intercept.map { meta, f -> f } )
        ch_versions = ch_versions.mix( DUPRADAR.out.versions.first() )
    }

    emit:
    multiqc  = ch_multiqc
    versions = ch_versions
}
