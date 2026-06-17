/*
 * reporting — final deliverables. Aggregates QC into MultiQC, records exact
 * software versions, renders the four audience-specific HTML reports
 * (executive, technical, QC, differential), and writes SHA-256 checksums over
 * the primary deliverables for downstream verification.
 */

include { MULTIQC                 } from '../../modules/local/multiqc.nf'
include { DUMP_SOFTWARE_VERSIONS  } from '../../modules/local/dump_software_versions.nf'
include { RENDER_REPORT           } from '../../modules/local/render_report.nf'
include { CHECKSUMS               } from '../../modules/local/checksums.nf'

workflow REPORTING {

    take:
    ch_multiqc_files     // QC files for MultiQC
    ch_versions          // every versions.yml
    ch_report_inputs     // matrices + DE tables (deliverables)

    main:

    // ---- Software-version provenance ------------------------------------
    // Concatenate every versions.yml into one file first — staging many files
    // all named "versions.yml" into a single process collides.
    ch_collated_versions = ch_versions
        .unique()
        .collectFile(name: 'collated_versions.yml', newLine: true, sort: true)
    DUMP_SOFTWARE_VERSIONS( ch_collated_versions )

    // ---- MultiQC ---------------------------------------------------------
    def mqc_config = file("${projectDir}/assets/multiqc_config.yaml")
    def mqc_cfg    = mqc_config.exists() ? mqc_config : file("${projectDir}/assets/NO_CONFIG")
    def mqc_logo   = file("${projectDir}/assets/NO_LOGO")

    ch_multiqc = Channel.empty()
    if (!params.skip_multiqc) {
        MULTIQC(
            ch_multiqc_files.collect().ifEmpty([]),
            mqc_cfg,
            mqc_logo,
            DUMP_SOFTWARE_VERSIONS.out.mqc
        )
        ch_multiqc = MULTIQC.out.report
    }

    // ---- Audience-specific reports --------------------------------------
    if (!params.skip_report) {
        ch_templates = Channel.fromList([
            [ 'executive',    file("${projectDir}/assets/report/executive_report.qmd")    ],
            [ 'technical',    file("${projectDir}/assets/report/technical_report.qmd")    ],
            [ 'qc',           file("${projectDir}/assets/report/qc_report.qmd")           ],
            [ 'differential', file("${projectDir}/assets/report/differential_report.qmd") ]
        ])
        ch_report_data = ch_report_inputs.mix(ch_multiqc).collect().ifEmpty([])
        RENDER_REPORT( ch_templates, ch_report_data )
    }

    // ---- Checksums over deliverables ------------------------------------
    if (params.write_checksums) {
        CHECKSUMS( ch_report_inputs.collect().ifEmpty([]) )
    }

    emit:
    multiqc = ch_multiqc
}
