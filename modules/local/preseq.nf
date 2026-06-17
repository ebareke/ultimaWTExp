// preseq lc_extrap — library-complexity / saturation curve to judge whether
// deeper sequencing would recover more distinct molecules. Tolerant of shallow
// libraries (errorStrategy ignore set in conf/base for the QC tier).
process PRESEQ {
    tag   "${meta.id}"
    label 'process_low'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.lc_extrap.txt"), emit: ccurve, optional: true
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def pe   = meta.single_end ? '' : '-pe'
    """
    preseq lc_extrap ${args} ${pe} -o ${meta.id}.lc_extrap.txt ${bam} || \\
        echo "preseq failed (library too shallow); skipping" > ${meta.id}.lc_extrap.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        preseq: \$(preseq 2>&1 | grep -i version | sed 's/^.*Version: //' || echo NA)
    END_VERSIONS
    """

    stub:
    "touch ${meta.id}.lc_extrap.txt versions.yml"
}
