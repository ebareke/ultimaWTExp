// Qualimap rnaseq — gene-body coverage, reads-genomic-origin and transcript
// coverage QC. Strand protocol mapped from the sample sheet.
process QUALIMAP_RNASEQ {
    tag   "${meta.id}"
    label 'process_medium'

    input:
    tuple val(meta), path(bam), path(bai)
    path  gtf

    output:
    tuple val(meta), path("${meta.id}_qualimap"), emit: results
    path "versions.yml", emit: versions

    script:
    def protocol = 'non-strand-specific'
    if (meta.strandedness == 'forward') protocol = 'strand-specific-forward'
    if (meta.strandedness == 'reverse') protocol = 'strand-specific-reverse'
    def paired = meta.single_end ? '' : '--paired'
    def avail  = (task.memory.toGiga() - 1)
    """
    unset DISPLAY
    qualimap --java-mem-size=${avail}G rnaseq \\
        -bam ${bam} \\
        -gtf ${gtf} \\
        -p ${protocol} ${paired} \\
        -outdir ${meta.id}_qualimap

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qualimap: \$(qualimap --version 2>&1 | grep -i 'QualiMap v' | sed 's/.*v\\.//' || echo NA)
    END_VERSIONS
    """

    stub:
    """
    mkdir -p ${meta.id}_qualimap
    touch ${meta.id}_qualimap/rnaseq_qc_results.txt
    touch versions.yml
    """
}
