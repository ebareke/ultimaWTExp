// Salmon quant — transcript-level quantification (selective alignment) against
// the decoy-aware index. libType -A lets Salmon infer strandedness unless the
// sample sheet pins it. quant.sf feeds tximport for gene-level summarisation.
process SALMON_QUANT {
    tag   "${meta.id}"
    label 'process_medium'

    input:
    tuple val(meta), path(reads)
    path  index

    output:
    tuple val(meta), path("${meta.id}_salmon"), emit: results
    path "versions.yml", emit: versions

    script:
    def args   = task.ext.args ?: ''
    def libtype = 'A'
    if (meta.strandedness == 'forward') libtype = meta.single_end ? 'SF' : 'ISF'
    if (meta.strandedness == 'reverse') libtype = meta.single_end ? 'SR' : 'ISR'
    if (meta.strandedness == 'unstranded') libtype = meta.single_end ? 'U' : 'IU'
    def input_reads = meta.single_end ? "-r ${reads[0]}" : "-1 ${reads[0]} -2 ${reads[1]}"
    """
    salmon quant \\
        --index ${index} \\
        --libType ${libtype} \\
        ${input_reads} \\
        --threads ${task.cpus} \\
        ${args} \\
        -o ${meta.id}_salmon

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        salmon: \$(salmon --version | sed 's/salmon //')
    END_VERSIONS
    """

    stub:
    """
    mkdir -p ${meta.id}_salmon
    printf 'Name\\tLength\\tEffectiveLength\\tTPM\\tNumReads\\ntx1\\t100\\t80\\t1000\\t50\\ntx2\\t200\\t180\\t500\\t30\\n' > ${meta.id}_salmon/quant.sf
    echo '{}' > ${meta.id}_salmon/cmd_info.json
    touch versions.yml
    """
}
