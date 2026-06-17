// dupRadar — distinguishes technical (PCR) from expression-driven duplication
// by modelling duplication rate vs expression. A flat curve = clean library;
// a high intercept = PCR artefact. Delegates to bin/dupradar.r.
process DUPRADAR {
    tag   "${meta.id}"
    label 'process_medium'

    input:
    tuple val(meta), path(bam), path(bai)
    path  gtf

    output:
    tuple val(meta), path("*_dupMatrix.txt"),        emit: matrix,   optional: true
    tuple val(meta), path("*_duprateExpDens.pdf"),   emit: density,  optional: true
    tuple val(meta), path("*_intercept_slope.txt"),  emit: intercept, optional: true
    path "versions.yml", emit: versions

    script:
    def strand = meta.strandedness == 'forward' ? 1 : (meta.strandedness == 'reverse' ? 2 : 0)
    def paired = meta.single_end ? 'single' : 'paired'
    """
    dupradar.r ${bam} ${meta.id} ${gtf} ${strand} ${paired} ${task.cpus}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioconductor-dupradar: \$(Rscript -e 'cat(as.character(packageVersion("dupRadar")))' 2>/dev/null || echo NA)
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}_dupMatrix.txt ${meta.id}_duprateExpDens.pdf ${meta.id}_intercept_slope.txt
    touch versions.yml
    """
}
