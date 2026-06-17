// gtf2bed — derive a 12-column BED of gene models from the GTF for RSeQC
// (which needs BED12, not GTF). Uses UCSC gtfToGenePred + genePredToBed.
process GTF2BED {
    tag   "${gtf.name}"
    label 'process_single'

    input:
    path gtf

    output:
    path "*.bed", emit: bed
    path "versions.yml", emit: versions

    script:
    def prefix = gtf.baseName
    """
    set -euo pipefail
    gtfToGenePred -genePredExt -ignoreGroupsWithoutExons ${gtf} ${prefix}.genepred
    genePredToBed ${prefix}.genepred ${prefix}.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ucsc: 'gtfToGenePred/genePredToBed'
    END_VERSIONS
    """

    stub:
    def prefix = gtf.baseName
    """
    printf 'chr1\\t0\\t100\\tgene1\\t0\\t+\\t0\\t100\\t0\\t1\\t100,\\t0,\\n' > ${prefix}.bed
    touch versions.yml
    """
}
