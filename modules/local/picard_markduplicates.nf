// Picard MarkDuplicates — flags optical/PCR duplicates and emits a metrics file
// for MultiQC. RNA-seq keeps duplicates for quantification (high-expression
// genes legitimately duplicate), so this is QC-only — the deduplicated BAM is
// published only when --save_align_intermeds is set.
process PICARD_MARKDUPLICATES {
    tag   "${meta.id}"
    label 'process_medium'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.markdup.bam"),  emit: bam
    tuple val(meta), path("*.metrics.txt"),  emit: metrics
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}.markdup"
    def avail  = (task.memory.toGiga() - 1)
    """
    picard -Xmx${avail}g MarkDuplicates \\
        INPUT=${bam} \\
        OUTPUT=${prefix}.bam \\
        METRICS_FILE=${prefix}.metrics.txt \\
        ASSUME_SORT_ORDER=coordinate \\
        VALIDATION_STRINGENCY=LENIENT

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        picard: \$(picard MarkDuplicates --version 2>&1 | grep -o '[0-9.]*' | head -n1 || echo NA)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}.markdup"
    """
    touch ${prefix}.bam ${prefix}.metrics.txt versions.yml
    """
}
