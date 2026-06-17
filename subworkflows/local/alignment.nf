/*
 * alignment — map trimmed reads with the chosen aligner (STAR and/or HISAT2)
 * and gather samtools alignment QC. STAR additionally yields native gene counts
 * and (when enabled) chimeric junctions for STAR-Fusion. Produces a unified
 * (meta, bam, bai) channel for all downstream BAM consumers.
 */

include { STAR_ALIGN          } from '../../modules/local/star_align.nf'
include { HISAT2_ALIGN        } from '../../modules/local/hisat2_align.nf'
include { SAMTOOLS_STATS      } from '../../modules/local/samtools_qc.nf'
include { SAMTOOLS_FLAGSTAT   } from '../../modules/local/samtools_qc.nf'
include { SAMTOOLS_IDXSTATS   } from '../../modules/local/samtools_qc.nf'

workflow ALIGNMENT {

    take:
    ch_reads          // tuple(meta, [reads])
    ch_star_index
    ch_hisat2_index
    ch_gtf

    main:
    ch_versions   = Channel.empty()
    ch_multiqc    = Channel.empty()
    ch_bam_bai    = Channel.empty()
    ch_star_counts = Channel.empty()
    ch_chimeric   = Channel.empty()

    if (params.aligner in ['star', 'star_hisat2']) {
        STAR_ALIGN( ch_reads, ch_star_index.collect(), ch_gtf )
        ch_bam_bai     = STAR_ALIGN.out.bam.join( STAR_ALIGN.out.bai )
        ch_star_counts = STAR_ALIGN.out.counts
        ch_chimeric    = STAR_ALIGN.out.chimeric
        ch_multiqc     = ch_multiqc.mix( STAR_ALIGN.out.log_final.map { meta, l -> l } )
        ch_versions    = ch_versions.mix( STAR_ALIGN.out.versions.first() )
    }

    if (params.aligner == 'hisat2') {
        HISAT2_ALIGN( ch_reads, ch_hisat2_index.collect() )
        ch_bam_bai  = HISAT2_ALIGN.out.bam.join( HISAT2_ALIGN.out.bai )
        ch_multiqc  = ch_multiqc.mix( HISAT2_ALIGN.out.log.map { meta, l -> l } )
        ch_versions = ch_versions.mix( HISAT2_ALIGN.out.versions.first() )
    }

    // ---- samtools alignment QC ------------------------------------------
    SAMTOOLS_STATS( ch_bam_bai )
    SAMTOOLS_FLAGSTAT( ch_bam_bai )
    SAMTOOLS_IDXSTATS( ch_bam_bai )
    ch_multiqc  = ch_multiqc
        .mix( SAMTOOLS_STATS.out.stats.map      { meta, f -> f } )
        .mix( SAMTOOLS_FLAGSTAT.out.flagstat.map { meta, f -> f } )
        .mix( SAMTOOLS_IDXSTATS.out.idxstats.map { meta, f -> f } )
    ch_versions = ch_versions.mix( SAMTOOLS_STATS.out.versions.first() )

    emit:
    bam_bai      = ch_bam_bai          // tuple(meta, bam, bai)
    star_counts  = ch_star_counts      // tuple(meta, ReadsPerGene.out.tab)
    chimeric     = ch_chimeric         // tuple(meta, Chimeric.out.junction)
    multiqc      = ch_multiqc
    versions     = ch_versions
}
