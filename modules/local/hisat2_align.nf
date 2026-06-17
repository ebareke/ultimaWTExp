// HISAT2 alignment — splice-aware mapping, piped straight to a coordinate-sorted
// indexed BAM. Strandedness from the sample sheet sets --rna-strandness.
process HISAT2_ALIGN {
    tag   "${meta.id}"
    label 'process_high'

    input:
    tuple val(meta), path(reads)
    path  index

    output:
    tuple val(meta), path("*.sorted.bam"),     emit: bam
    tuple val(meta), path("*.sorted.bam.bai"), emit: bai
    tuple val(meta), path("*.hisat2.log"),     emit: log
    path "versions.yml", emit: versions

    script:
    def prefix = meta.id
    def args   = task.ext.args ?: ''
    def strand = ''
    if (meta.strandedness == 'forward') strand = meta.single_end ? '--rna-strandness F' : '--rna-strandness FR'
    if (meta.strandedness == 'reverse') strand = meta.single_end ? '--rna-strandness R' : '--rna-strandness RF'
    def input_reads = meta.single_end ? "-U ${reads[0]}" : "-1 ${reads[0]} -2 ${reads[1]}"
    """
    set -euo pipefail
    INDEX=\$(find -L ${index} -name "*.1.ht2*" | sed 's/\\.1\\.ht2.*//' | head -n1)

    hisat2 \\
        -x \$INDEX \\
        ${input_reads} \\
        --threads ${task.cpus} \\
        --new-summary --summary-file ${prefix}.hisat2.log \\
        ${strand} ${args} \\
        | samtools sort -@ ${task.cpus} -o ${prefix}.sorted.bam -

    samtools index -@ ${task.cpus} ${prefix}.sorted.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hisat2: \$(hisat2 --version | head -n1 | sed 's/^.*version //')
        samtools: \$(samtools --version | head -n1 | sed 's/samtools //')
    END_VERSIONS
    """

    stub:
    def prefix = meta.id
    """
    touch ${prefix}.sorted.bam ${prefix}.sorted.bam.bai ${prefix}.hisat2.log
    touch versions.yml
    """
}
