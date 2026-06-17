// samtools stats / flagstat / idxstats — alignment-level QC metrics consumed by
// MultiQC. Three small, independent processes in one module file.

process SAMTOOLS_STATS {
    tag   "${meta.id}"
    label 'process_low'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.stats"), emit: stats
    path "versions.yml", emit: versions

    script:
    """
    samtools stats --threads ${task.cpus} ${bam} > ${meta.id}.stats
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools --version | head -n1 | sed 's/samtools //')
    END_VERSIONS
    """

    stub:
    "touch ${meta.id}.stats versions.yml"
}

process SAMTOOLS_FLAGSTAT {
    tag   "${meta.id}"
    label 'process_low'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.flagstat"), emit: flagstat
    path "versions.yml", emit: versions

    script:
    """
    samtools flagstat --threads ${task.cpus} ${bam} > ${meta.id}.flagstat
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools --version | head -n1 | sed 's/samtools //')
    END_VERSIONS
    """

    stub:
    "touch ${meta.id}.flagstat versions.yml"
}

process SAMTOOLS_IDXSTATS {
    tag   "${meta.id}"
    label 'process_low'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.idxstats"), emit: idxstats
    path "versions.yml", emit: versions

    script:
    """
    samtools idxstats ${bam} > ${meta.id}.idxstats
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools --version | head -n1 | sed 's/samtools //')
    END_VERSIONS
    """

    stub:
    "touch ${meta.id}.idxstats versions.yml"
}
