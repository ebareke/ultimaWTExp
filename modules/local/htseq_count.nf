// HTSeq-count — alternative gene-level counter (union mode), per sample.
process HTSEQ_COUNT {
    tag   "${meta.id}"
    label 'process_medium'

    input:
    tuple val(meta), path(bam), path(bai)
    path  gtf

    output:
    tuple val(meta), path("*.htseq.txt"), emit: counts
    path "versions.yml", emit: versions

    script:
    def prefix = meta.id
    def args   = task.ext.args ?: ''
    def strand = meta.strandedness == 'forward' ? 'yes' : (meta.strandedness == 'reverse' ? 'reverse' : 'no')
    """
    htseq-count \\
        -n ${task.cpus} \\
        -s ${strand} \\
        -i ${params.fc_group_features} \\
        -t ${params.fc_count_type} \\
        ${args} \\
        ${bam} ${gtf} > ${prefix}.htseq.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        htseq: \$(htseq-count --version 2>&1 | sed 's/^.* //')
    END_VERSIONS
    """

    stub:
    def prefix = meta.id
    """
    printf 'gene1\\t50\\ngene2\\t30\\n__no_feature\\t5\\n' > ${prefix}.htseq.txt
    touch versions.yml
    """
}
