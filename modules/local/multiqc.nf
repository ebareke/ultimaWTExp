// MultiQC — aggregate every QC + log file (FastQC, fastp, STAR/HISAT2, samtools,
// Picard, Qualimap, RSeQC, preseq, dupRadar, featureCounts/Salmon, software
// versions) into one interactive HTML report.
process MULTIQC {
    label 'process_low'

    input:
    path  multiqc_files, stageAs: "?/*"
    path  config
    path  logo
    path  versions

    output:
    path "*multiqc_report.html", emit: report
    path "*_data",               emit: data
    path "*_plots", optional: true, emit: plots
    path "versions.yml", emit: versions

    script:
    def args   = task.ext.args ?: ''
    def cfg     = config.name != 'NO_CONFIG' ? "--config ${config}" : ''
    """
    multiqc -f ${args} ${cfg} .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$(multiqc --version | sed 's/^.*version //')
    END_VERSIONS
    """

    stub:
    """
    mkdir -p multiqc_report_data
    touch multiqc_report.html
    touch versions.yml
    """
}
