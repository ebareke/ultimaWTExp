/*
 * ===========================================================================
 * RNASEQ — the end-to-end workflow.
 *
 * Reference  ─▶ Preprocessing ─▶ Alignment ─▶ Post-align QC
 *                                   │  ├─▶ Quantification ─▶ Differential Expr. ─▶ Functional
 *                                   │  ├─▶ Fusion (STAR-Fusion)
 *                                   │  └─▶ Splicing (rMATS)
 *                                   └────────────────────────────────────▶ Reporting (MultiQC + HTML)
 * ===========================================================================
 */

include { PREPARE_REFERENCE       } from '../subworkflows/local/prepare_reference.nf'
include { PREPROCESSING           } from '../subworkflows/local/preprocessing.nf'
include { ALIGNMENT               } from '../subworkflows/local/alignment.nf'
include { POSTALIGN_QC            } from '../subworkflows/local/postalign_qc.nf'
include { QUANTIFICATION          } from '../subworkflows/local/quantification.nf'
include { FUSION                  } from '../subworkflows/local/fusion.nf'
include { SPLICING                } from '../subworkflows/local/splicing.nf'
include { DIFFERENTIAL_EXPRESSION } from '../subworkflows/local/differential_expression.nf'
include { FUNCTIONAL              } from '../subworkflows/local/functional.nf'
include { REPORTING               } from '../subworkflows/local/reporting.nf'

workflow RNASEQ {

    take:
    ch_reads          // tuple(meta, [reads])

    main:
    ch_versions      = Channel.empty()
    ch_multiqc_files = Channel.empty()
    ch_report_inputs = Channel.empty()

    // 1) Reference -----------------------------------------------------------
    PREPARE_REFERENCE()
    ch_versions = ch_versions.mix( PREPARE_REFERENCE.out.versions )

    // 2) Pre-alignment QC + trimming ----------------------------------------
    PREPROCESSING( ch_reads )
    ch_versions      = ch_versions.mix( PREPROCESSING.out.versions )
    ch_multiqc_files = ch_multiqc_files.mix( PREPROCESSING.out.multiqc )

    // 3) Alignment ----------------------------------------------------------
    ALIGNMENT(
        PREPROCESSING.out.reads,
        PREPARE_REFERENCE.out.star_index,
        PREPARE_REFERENCE.out.hisat2_index,
        PREPARE_REFERENCE.out.gtf
    )
    ch_versions      = ch_versions.mix( ALIGNMENT.out.versions )
    ch_multiqc_files = ch_multiqc_files.mix( ALIGNMENT.out.multiqc )

    // 4) Post-alignment QC --------------------------------------------------
    POSTALIGN_QC(
        ALIGNMENT.out.bam_bai,
        PREPARE_REFERENCE.out.gtf,
        PREPARE_REFERENCE.out.gene_bed
    )
    ch_versions      = ch_versions.mix( POSTALIGN_QC.out.versions )
    ch_multiqc_files = ch_multiqc_files.mix( POSTALIGN_QC.out.multiqc )

    // 5) Quantification -----------------------------------------------------
    QUANTIFICATION(
        PREPROCESSING.out.reads,
        ALIGNMENT.out.bam_bai,
        ALIGNMENT.out.star_counts,
        PREPARE_REFERENCE.out.gtf,
        PREPARE_REFERENCE.out.salmon_index,
        PREPARE_REFERENCE.out.tx2gene
    )
    ch_versions      = ch_versions.mix( QUANTIFICATION.out.versions )
    ch_multiqc_files = ch_multiqc_files.mix( QUANTIFICATION.out.multiqc )
    ch_report_inputs = ch_report_inputs
        .mix( QUANTIFICATION.out.counts_raw )
        .mix( QUANTIFICATION.out.tpm )

    // 6) Fusion -------------------------------------------------------------
    if (params.run_fusion && params.aligner in ['star', 'star_hisat2'] && params.star_chimeric) {
        FUSION( ALIGNMENT.out.chimeric )
        ch_versions = ch_versions.mix( FUSION.out.versions )
    }

    // 7) Splicing -----------------------------------------------------------
    if (params.run_splicing && params.design) {
        SPLICING( ALIGNMENT.out.bam_bai, PREPARE_REFERENCE.out.gtf )
        ch_versions = ch_versions.mix( SPLICING.out.versions )
    }

    // 8) Differential expression + 9) Functional ---------------------------
    if (params.run_dge && params.design) {
        DIFFERENTIAL_EXPRESSION( QUANTIFICATION.out.counts_raw )
        ch_versions      = ch_versions.mix( DIFFERENTIAL_EXPRESSION.out.versions )
        ch_report_inputs = ch_report_inputs.mix(
            DIFFERENTIAL_EXPRESSION.out.de_results.map { c, f -> f }
        )

        if (params.run_enrichment) {
            FUNCTIONAL( DIFFERENTIAL_EXPRESSION.out.de_results )
            ch_versions = ch_versions.mix( FUNCTIONAL.out.versions )
        }
    }

    // 10) Reporting ---------------------------------------------------------
    REPORTING(
        ch_multiqc_files,
        ch_versions,            // every emitted versions.yml
        ch_report_inputs
    )
}
