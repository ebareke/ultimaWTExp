// fastp — adapter + quality trimming with polyG/polyX removal (default trimmer).
// Adapter detection is automatic for PE; SE uses fastp's overrepresentation
// model. Emits a JSON for MultiQC and the count of surviving reads so the
// pipeline can drop libraries that fall below --min_trimmed_reads.
process FASTP {
    tag   "${meta.id}"
    label 'process_medium'

    input:
    tuple val(meta), path(reads)
    path  adapter_fasta

    output:
    tuple val(meta), path("*.fastp.fastq.gz"), emit: reads
    tuple val(meta), path("*.fastp.json"),     emit: json
    tuple val(meta), path("*.fastp.html"),     emit: html
    tuple val(meta), path("*.fastp.log"),      emit: log
    path "versions.yml", emit: versions

    script:
    def prefix  = task.ext.prefix ?: meta.id
    def args    = task.ext.args ?: ''
    def adapter = adapter_fasta.name != 'NO_ADAPTERS' ? "--adapter_fasta ${adapter_fasta}" : ''
    if (meta.single_end) {
        """
        fastp \\
            --in1 ${reads[0]} \\
            --out1 ${prefix}.fastp.fastq.gz \\
            --thread ${task.cpus} \\
            --json ${prefix}.fastp.json \\
            --html ${prefix}.fastp.html \\
            ${adapter} ${args} \\
            2> ${prefix}.fastp.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            fastp: \$(fastp --version 2>&1 | sed 's/^fastp //')
        END_VERSIONS
        """
    } else {
        """
        fastp \\
            --in1 ${reads[0]} --in2 ${reads[1]} \\
            --out1 ${prefix}_1.fastp.fastq.gz --out2 ${prefix}_2.fastp.fastq.gz \\
            --thread ${task.cpus} \\
            --detect_adapter_for_pe \\
            --json ${prefix}.fastp.json \\
            --html ${prefix}.fastp.html \\
            ${adapter} ${args} \\
            2> ${prefix}.fastp.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            fastp: \$(fastp --version 2>&1 | sed 's/^fastp //')
        END_VERSIONS
        """
    }

    stub:
    def prefix = task.ext.prefix ?: meta.id
    def outs   = meta.single_end ? ["${prefix}.fastp.fastq.gz"]
                                 : ["${prefix}_1.fastp.fastq.gz", "${prefix}_2.fastp.fastq.gz"]
    """
    ${outs.collect { "echo | gzip > ${it}" }.join('\n    ')}
    touch ${prefix}.fastp.json ${prefix}.fastp.html ${prefix}.fastp.log
    touch versions.yml
    """
}
