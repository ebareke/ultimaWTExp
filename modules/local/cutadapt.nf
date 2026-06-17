// Cutadapt — explicit adapter/quality trimming, alternative trimmer.
process CUTADAPT {
    tag   "${meta.id}"
    label 'process_medium'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.trim.fastq.gz"), emit: reads
    tuple val(meta), path("*.cutadapt.log"),  emit: log
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: meta.id
    def args   = task.ext.args ?: ''
    if (meta.single_end) {
        """
        cutadapt ${args} -j ${task.cpus} \\
            -o ${prefix}.trim.fastq.gz ${reads[0]} > ${prefix}.cutadapt.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            cutadapt: \$(cutadapt --version)
        END_VERSIONS
        """
    } else {
        """
        cutadapt ${args} -j ${task.cpus} \\
            -o ${prefix}_1.trim.fastq.gz -p ${prefix}_2.trim.fastq.gz \\
            ${reads[0]} ${reads[1]} > ${prefix}.cutadapt.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            cutadapt: \$(cutadapt --version)
        END_VERSIONS
        """
    }

    stub:
    def prefix = task.ext.prefix ?: meta.id
    def outs   = meta.single_end ? ["${prefix}.trim.fastq.gz"]
                                 : ["${prefix}_1.trim.fastq.gz", "${prefix}_2.trim.fastq.gz"]
    """
    ${outs.collect { "echo | gzip > ${it}" }.join('\n    ')}
    touch ${prefix}.cutadapt.log
    touch versions.yml
    """
}
