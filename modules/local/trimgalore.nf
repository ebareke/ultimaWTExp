// Trim Galore! — Cutadapt + FastQC wrapper, alternative trimmer.
process TRIMGALORE {
    tag   "${meta.id}"
    label 'process_medium'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fq.gz"),            emit: reads
    tuple val(meta), path("*trimming_report.txt"), emit: log
    path "*.{html,zip}", optional: true,         emit: fastqc
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def pe   = meta.single_end ? '' : '--paired'
    """
    trim_galore ${pe} --cores ${task.cpus} --gzip ${args} ${reads}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        trimgalore: \$(trim_galore --version | sed -n 's/.*version *//p')
        cutadapt: \$(cutadapt --version)
    END_VERSIONS
    """

    stub:
    def outs = meta.single_end ? ["${meta.id}_trimmed.fq.gz"]
                               : ["${meta.id}_1_val_1.fq.gz", "${meta.id}_2_val_2.fq.gz"]
    """
    ${outs.collect { "echo | gzip > ${it}" }.join('\n    ')}
    touch ${meta.id}.fastq.gz_trimming_report.txt
    touch versions.yml
    """
}
