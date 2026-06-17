/*
 * preprocessing — raw-read QC, optional adapter/quality trimming, post-trim QC,
 * optional contamination screen. Returns the reads that downstream alignment
 * should use (trimmed, or raw if --skip_trimming/--trimmer none) plus all QC
 * artefacts for MultiQC.
 */

include { FASTQC as FASTQC_RAW  } from '../../modules/local/fastqc.nf'
include { FASTQC as FASTQC_TRIM } from '../../modules/local/fastqc.nf'
include { FASTQ_SCREEN          } from '../../modules/local/fastq_screen.nf'
include { FASTP                 } from '../../modules/local/fastp.nf'
include { TRIMGALORE            } from '../../modules/local/trimgalore.nf'
include { CUTADAPT              } from '../../modules/local/cutadapt.nf'

workflow PREPROCESSING {

    take:
    ch_reads          // tuple(meta, [reads])

    main:
    ch_versions = Channel.empty()
    ch_multiqc  = Channel.empty()

    // ---- Raw-read QC -----------------------------------------------------
    if (!params.skip_fastqc) {
        FASTQC_RAW( ch_reads )
        ch_multiqc  = ch_multiqc.mix( FASTQC_RAW.out.zip.map { meta, z -> z } )
        ch_versions = ch_versions.mix( FASTQC_RAW.out.versions.first() )
    }

    // ---- Optional contamination screen -----------------------------------
    if (!params.skip_fastq_screen && params.fastq_screen_conf) {
        FASTQ_SCREEN( ch_reads, file(params.fastq_screen_conf, checkIfExists: true) )
        ch_multiqc  = ch_multiqc.mix( FASTQ_SCREEN.out.txt.map { meta, t -> t } )
        ch_versions = ch_versions.mix( FASTQ_SCREEN.out.versions.first() )
    }

    // ---- Trimming --------------------------------------------------------
    if (params.skip_trimming || params.trimmer == 'none') {
        ch_trimmed = ch_reads
    } else if (params.trimmer == 'fastp') {
        def adapters = params.adapter_fasta ? file(params.adapter_fasta, checkIfExists: true)
                                            : file("${projectDir}/assets/NO_ADAPTERS")
        FASTP( ch_reads, adapters )
        ch_trimmed  = FASTP.out.reads
        ch_multiqc  = ch_multiqc.mix( FASTP.out.json.map { meta, j -> j } )
        ch_versions = ch_versions.mix( FASTP.out.versions.first() )
    } else if (params.trimmer == 'trimgalore') {
        TRIMGALORE( ch_reads )
        ch_trimmed  = TRIMGALORE.out.reads
        ch_multiqc  = ch_multiqc.mix( TRIMGALORE.out.log.map { meta, l -> l } )
        ch_versions = ch_versions.mix( TRIMGALORE.out.versions.first() )
    } else {  // cutadapt
        CUTADAPT( ch_reads )
        ch_trimmed  = CUTADAPT.out.reads
        ch_multiqc  = ch_multiqc.mix( CUTADAPT.out.log.map { meta, l -> l } )
        ch_versions = ch_versions.mix( CUTADAPT.out.versions.first() )
    }

    // ---- Post-trim QC ----------------------------------------------------
    if (!params.skip_fastqc && !(params.skip_trimming || params.trimmer == 'none')) {
        FASTQC_TRIM( ch_trimmed )
        ch_multiqc  = ch_multiqc.mix( FASTQC_TRIM.out.zip.map { meta, z -> z } )
        ch_versions = ch_versions.mix( FASTQC_TRIM.out.versions.first() )
    }

    emit:
    reads        = ch_trimmed
    multiqc      = ch_multiqc
    versions     = ch_versions
}
