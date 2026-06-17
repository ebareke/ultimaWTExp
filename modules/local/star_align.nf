// STAR alignment — coordinate-sorted BAM + per-gene counts in one pass.
// Optional 2-pass mode (better novel-junction sensitivity) and chimeric output
// (consumed by STAR-Fusion). GeneCounts gives a STAR-native gene-level matrix
// "for free" alongside the BAM used by featureCounts/HTSeq.
process STAR_ALIGN {
    tag   "${meta.id}"
    label 'process_high'

    input:
    tuple val(meta), path(reads)
    path  index
    path  gtf

    output:
    tuple val(meta), path("*.Aligned.sortedByCoord.out.bam"), emit: bam
    tuple val(meta), path("*.bai"),                           emit: bai
    tuple val(meta), path("*.ReadsPerGene.out.tab"),          emit: counts
    tuple val(meta), path("*.SJ.out.tab"),                    emit: junctions, optional: true
    tuple val(meta), path("*.Chimeric.out.junction"),         emit: chimeric,  optional: true
    tuple val(meta), path("*.Log.final.out"),                 emit: log_final
    path "*.Log.out", emit: log
    path "versions.yml", emit: versions

    script:
    def prefix    = meta.id
    def args      = task.ext.args ?: ''
    def twopass   = params.star_two_pass ? '--twopassMode Basic' : ''
    def chimeric  = params.star_chimeric ?
        '--chimSegmentMin 12 --chimJunctionOverhangMin 8 --chimOutType Junctions --chimMultimapNmax 20' : ''
    def readgzip  = reads[0].name.endsWith('.gz') ? '--readFilesCommand zcat' : ''
    def readstr   = meta.single_end ? "${reads[0]}" : "${reads[0]} ${reads[1]}"
    """
    set -euo pipefail
    STAR \\
        --runMode alignReads \\
        --genomeDir ${index} \\
        --readFilesIn ${readstr} \\
        ${readgzip} \\
        --runThreadN ${task.cpus} \\
        --outSAMtype BAM SortedByCoordinate \\
        --quantMode GeneCounts \\
        --outSAMattrRGline ID:${prefix} SM:${prefix} PL:ILLUMINA \\
        ${twopass} ${chimeric} ${args} \\
        --outFileNamePrefix ${prefix}.

    samtools index -@ ${task.cpus} ${prefix}.Aligned.sortedByCoord.out.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$(STAR --version)
        samtools: \$(samtools --version | head -n1 | sed 's/samtools //')
    END_VERSIONS
    """

    stub:
    def prefix = meta.id
    """
    touch ${prefix}.Aligned.sortedByCoord.out.bam
    touch ${prefix}.Aligned.sortedByCoord.out.bam.bai
    printf 'N_unmapped\\t0\\t0\\t0\\ngene1\\t100\\t100\\t100\\n' > ${prefix}.ReadsPerGene.out.tab
    touch ${prefix}.SJ.out.tab
    ${params.star_chimeric ? "touch ${prefix}.Chimeric.out.junction" : ''}
    touch ${prefix}.Log.final.out ${prefix}.Log.out
    touch versions.yml
    """
}
