// Picard CollectRnaSeqMetrics — coverage uniformity (5'->3' bias), and the
// coding/UTR/intronic/intergenic breakdown. Derives the required refFlat from
// the GTF on the fly with UCSC gtfToGenePred so no extra reference is needed.
process PICARD_RNASEQMETRICS {
    tag   "${meta.id}"
    label 'process_medium'

    input:
    tuple val(meta), path(bam), path(bai)
    path  gtf

    output:
    tuple val(meta), path("*.rna_metrics.txt"), emit: metrics
    path "versions.yml", emit: versions

    script:
    def prefix = meta.id
    def strand = 'NONE'
    if (meta.strandedness == 'forward') strand = 'FIRST_READ_TRANSCRIPTION_STRAND'
    if (meta.strandedness == 'reverse') strand = 'SECOND_READ_TRANSCRIPTION_STRAND'
    def avail  = (task.memory.toGiga() - 1)
    """
    set -euo pipefail
    gtfToGenePred -genePredExt -ignoreGroupsWithoutExons ${gtf} refflat.tmp
    paste <(cut -f12 refflat.tmp) <(cut -f1-10 refflat.tmp) > refFlat.txt

    picard -Xmx${avail}g CollectRnaSeqMetrics \\
        INPUT=${bam} \\
        OUTPUT=${prefix}.rna_metrics.txt \\
        REF_FLAT=refFlat.txt \\
        STRAND_SPECIFICITY=${strand} \\
        VALIDATION_STRINGENCY=LENIENT

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        picard: \$(picard CollectRnaSeqMetrics --version 2>&1 | grep -o '[0-9.]*' | head -n1 || echo NA)
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}.rna_metrics.txt versions.yml
    """
}
