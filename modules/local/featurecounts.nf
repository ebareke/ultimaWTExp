// featureCounts (subread) — gene-level read summarisation, run per sample so
// strandedness can be set from each sample's metadata, then merged downstream.
// Auto-detects paired-end and feeds -p/--countReadPairs accordingly.
process FEATURECOUNTS {
    tag   "${meta.id}"
    label 'process_medium'

    input:
    tuple val(meta), path(bam), path(bai)
    path  gtf

    output:
    tuple val(meta), path("*.featureCounts.txt"),         emit: counts
    tuple val(meta), path("*.featureCounts.txt.summary"), emit: summary
    path "versions.yml", emit: versions

    script:
    def prefix = meta.id
    def args   = task.ext.args ?: ''
    def strand = meta.strandedness == 'forward' ? 1 : (meta.strandedness == 'reverse' ? 2 : 0)
    def paired = meta.single_end ? '' : '-p --countReadPairs'
    def extra  = params.fc_extra_attributes ? "--extraAttributes ${params.fc_extra_attributes}" : ''
    """
    featureCounts \\
        -T ${task.cpus} \\
        -a ${gtf} \\
        -s ${strand} ${paired} ${extra} ${args} \\
        -o ${prefix}.featureCounts.txt \\
        ${bam}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        featurecounts: \$(featureCounts -v 2>&1 | grep -o 'v[0-9.]*' | head -n1 | sed 's/^v//')
    END_VERSIONS
    """

    stub:
    def prefix = meta.id
    """
    printf '# Program:featureCounts\\nGeneid\\tChr\\tStart\\tEnd\\tStrand\\tLength\\t${prefix}\\ngene1\\tchr1\\t1\\t100\\t+\\t100\\t50\\ngene2\\tchr1\\t200\\t400\\t+\\t201\\t30\\n' > ${prefix}.featureCounts.txt
    printf 'Status\\t${prefix}\\nAssigned\\t80\\n' > ${prefix}.featureCounts.txt.summary
    touch versions.yml
    """
}
