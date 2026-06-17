/*
 * prepare_reference — turn raw FASTA/GTF(/GFF) into a validated, indexed
 * reference bundle. Decompresses, converts GFF->GTF, validates consistency,
 * derives a BED12 for RSeQC, and builds only the indices the chosen aligner /
 * pseudo-aligner needs (reusing prebuilt ones when supplied).
 */

include { GUNZIP as GUNZIP_FASTA } from '../../modules/local/gunzip.nf'
include { GUNZIP as GUNZIP_GTF   } from '../../modules/local/gunzip.nf'
include { GFFREAD               } from '../../modules/local/gffread.nf'
include { REFERENCE_CHECK       } from '../../modules/local/reference_check.nf'
include { GTF2BED               } from '../../modules/local/gtf2bed.nf'
include { STAR_GENOMEGENERATE   } from '../../modules/local/star_genomegenerate.nf'
include { HISAT2_BUILD          } from '../../modules/local/hisat2_build.nf'
include { SALMON_INDEX          } from '../../modules/local/salmon_index.nf'

workflow PREPARE_REFERENCE {

    main:
    ch_versions = Channel.empty()

    // ---- FASTA (decompress if needed) ------------------------------------
    if (params.fasta.endsWith('.gz')) {
        GUNZIP_FASTA( file(params.fasta, checkIfExists: true) )
        ch_fasta    = GUNZIP_FASTA.out.gunzip
        ch_versions = ch_versions.mix(GUNZIP_FASTA.out.versions)
    } else {
        ch_fasta = Channel.value( file(params.fasta, checkIfExists: true) )
    }

    // ---- Annotation: GTF, or GFF converted to GTF ------------------------
    if (params.gtf) {
        if (params.gtf.endsWith('.gz')) {
            GUNZIP_GTF( file(params.gtf, checkIfExists: true) )
            ch_gtf      = GUNZIP_GTF.out.gunzip
            ch_versions = ch_versions.mix(GUNZIP_GTF.out.versions)
        } else {
            ch_gtf = Channel.value( file(params.gtf, checkIfExists: true) )
        }
    } else {
        GFFREAD( file(params.gff, checkIfExists: true) )
        ch_gtf      = GFFREAD.out.gtf
        ch_versions = ch_versions.mix(GFFREAD.out.versions)
    }

    // ---- Validate the genome/annotation pair up front --------------------
    REFERENCE_CHECK( ch_fasta, ch_gtf )
    ch_versions = ch_versions.mix(REFERENCE_CHECK.out.versions)

    // ---- BED12 for RSeQC -------------------------------------------------
    if (params.gene_bed) {
        ch_gene_bed = Channel.value( file(params.gene_bed, checkIfExists: true) )
    } else {
        GTF2BED( ch_gtf )
        ch_gene_bed = GTF2BED.out.bed
        ch_versions = ch_versions.mix(GTF2BED.out.versions)
    }

    // ---- STAR index ------------------------------------------------------
    ch_star_index = Channel.empty()
    if (params.aligner in ['star', 'star_hisat2']) {
        if (params.star_index) {
            ch_star_index = Channel.value( file(params.star_index, checkIfExists: true) )
        } else {
            STAR_GENOMEGENERATE( ch_fasta, ch_gtf )
            ch_star_index = STAR_GENOMEGENERATE.out.index
            ch_versions   = ch_versions.mix(STAR_GENOMEGENERATE.out.versions)
        }
    }

    // ---- HISAT2 index ----------------------------------------------------
    ch_hisat2_index = Channel.empty()
    if (params.aligner in ['hisat2', 'star_hisat2']) {
        if (params.hisat2_index) {
            ch_hisat2_index = Channel.value( file(params.hisat2_index, checkIfExists: true) )
        } else {
            HISAT2_BUILD( ch_fasta, ch_gtf )
            ch_hisat2_index = HISAT2_BUILD.out.index
            ch_versions     = ch_versions.mix(HISAT2_BUILD.out.versions)
        }
    }

    // ---- Salmon index + tx2gene -----------------------------------------
    ch_salmon_index = Channel.empty()
    ch_tx2gene      = Channel.empty()
    if (params.pseudo_aligner == 'salmon') {
        if (params.salmon_index && params.transcript_fasta) {
            ch_salmon_index = Channel.value( file(params.salmon_index, checkIfExists: true) )
            // tx2gene still derived once for tximport
            SALMON_INDEX( ch_fasta,
                          file(params.transcript_fasta, checkIfExists: true),
                          ch_gtf )
            ch_tx2gene = SALMON_INDEX.out.tx2gene
        } else {
            def tx = params.transcript_fasta ? file(params.transcript_fasta, checkIfExists: true)
                                             : file("${projectDir}/assets/NO_TRANSCRIPTS")
            SALMON_INDEX( ch_fasta, tx, ch_gtf )
            ch_salmon_index = SALMON_INDEX.out.index
            ch_tx2gene      = SALMON_INDEX.out.tx2gene
            ch_versions     = ch_versions.mix(SALMON_INDEX.out.versions)
        }
    }

    emit:
    fasta        = ch_fasta
    gtf          = ch_gtf
    gene_bed     = ch_gene_bed
    star_index   = ch_star_index
    hisat2_index = ch_hisat2_index
    salmon_index = ch_salmon_index
    tx2gene      = ch_tx2gene
    versions     = ch_versions
}
