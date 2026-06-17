/*
 * quantification — gene-level counting (featureCounts | HTSeq | STAR) merged
 * into raw/TPM/FPKM/CPM matrices, and optional transcript-level quantification
 * with Salmon summarised to genes via tximport. The raw gene matrix is the
 * primary input to differential expression.
 */

include { FEATURECOUNTS } from '../../modules/local/featurecounts.nf'
include { HTSEQ_COUNT   } from '../../modules/local/htseq_count.nf'
include { MERGE_COUNTS  } from '../../modules/local/merge_counts.nf'
include { SALMON_QUANT  } from '../../modules/local/salmon_quant.nf'
include { TXIMPORT      } from '../../modules/local/tximport.nf'

workflow QUANTIFICATION {

    take:
    ch_reads          // tuple(meta, [trimmed reads])
    ch_bam_bai        // tuple(meta, bam, bai)
    ch_star_counts    // tuple(meta, ReadsPerGene.out.tab)
    ch_gtf
    ch_salmon_index
    ch_tx2gene

    main:
    ch_versions = Channel.empty()
    ch_multiqc  = Channel.empty()

    // ---- Gene-level counting --------------------------------------------
    if (params.gene_quant == 'featurecounts') {
        FEATURECOUNTS( ch_bam_bai, ch_gtf )
        ch_count_files = FEATURECOUNTS.out.counts.map { meta, f -> f }.collect()
        ch_multiqc  = ch_multiqc.mix( FEATURECOUNTS.out.summary.map { meta, f -> f } )
        ch_versions = ch_versions.mix( FEATURECOUNTS.out.versions.first() )
        MERGE_COUNTS( ch_count_files, 'featurecounts', ch_gtf )
    } else if (params.gene_quant == 'htseq') {
        HTSEQ_COUNT( ch_bam_bai, ch_gtf )
        ch_count_files = HTSEQ_COUNT.out.counts.map { meta, f -> f }.collect()
        ch_multiqc  = ch_multiqc.mix( HTSEQ_COUNT.out.counts.map { meta, f -> f } )
        ch_versions = ch_versions.mix( HTSEQ_COUNT.out.versions.first() )
        MERGE_COUNTS( ch_count_files, 'htseq', ch_gtf )
    } else {  // star native counts
        ch_count_files = ch_star_counts.map { meta, f -> f }.collect()
        MERGE_COUNTS( ch_count_files, 'star', ch_gtf )
    }
    ch_counts_raw = MERGE_COUNTS.out.raw
    ch_versions   = ch_versions.mix( MERGE_COUNTS.out.versions )

    // ---- Transcript-level (Salmon) --------------------------------------
    ch_salmon_gene_counts = Channel.empty()
    if (params.pseudo_aligner == 'salmon') {
        SALMON_QUANT( ch_reads, ch_salmon_index.collect() )
        ch_multiqc  = ch_multiqc.mix( SALMON_QUANT.out.results.map { meta, d -> d } )
        ch_versions = ch_versions.mix( SALMON_QUANT.out.versions.first() )

        TXIMPORT( SALMON_QUANT.out.results.map { meta, d -> d }.collect(), ch_tx2gene )
        ch_salmon_gene_counts = TXIMPORT.out.gene_counts
        ch_versions = ch_versions.mix( TXIMPORT.out.versions )
    }

    emit:
    counts_raw          = ch_counts_raw            // primary DE matrix
    tpm                 = MERGE_COUNTS.out.tpm
    fpkm                = MERGE_COUNTS.out.fpkm
    cpm                 = MERGE_COUNTS.out.cpm
    salmon_gene_counts  = ch_salmon_gene_counts
    multiqc             = ch_multiqc
    versions            = ch_versions
}
