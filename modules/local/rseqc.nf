// RSeQC — the canonical RNA-seq alignment QC battery. Bundles the metrics the
// SRS asks for: strandness inference, gene-body coverage, junction saturation,
// read distribution, plus bam_stat and inner-distance (PE). Each sub-tool is
// optional-tolerant: a failure in one report does not sink the others.
process RSEQC {
    tag   "${meta.id}"
    label 'process_medium'

    input:
    tuple val(meta), path(bam), path(bai)
    path  bed

    output:
    tuple val(meta), path("*.{txt,pdf,r,xls,json}"), emit: results, optional: true
    path "versions.yml", emit: versions

    script:
    def prefix = meta.id
    def inner  = meta.single_end ? '' : "inner_distance.py -i ${bam} -r ${bed} -o ${prefix} > /dev/null 2>&1 || true"
    """
    set +e
    infer_experiment.py    -i ${bam} -r ${bed}            > ${prefix}.infer_experiment.txt 2>&1
    read_distribution.py   -i ${bam} -r ${bed}            > ${prefix}.read_distribution.txt 2>&1
    bam_stat.py            -i ${bam}                      > ${prefix}.bam_stat.txt 2>&1
    junction_annotation.py -i ${bam} -r ${bed} -o ${prefix} > ${prefix}.junction_annotation.log 2>&1
    junction_saturation.py -i ${bam} -r ${bed} -o ${prefix} > /dev/null 2>&1
    geneBody_coverage.py   -i ${bam} -r ${bed} -o ${prefix} > /dev/null 2>&1
    read_duplication.py    -i ${bam} -o ${prefix}          > /dev/null 2>&1
    ${inner}
    set -e

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rseqc: \$(infer_experiment.py --version | sed 's/^.* //')
    END_VERSIONS
    """

    stub:
    def prefix = meta.id
    """
    touch ${prefix}.infer_experiment.txt ${prefix}.read_distribution.txt ${prefix}.bam_stat.txt
    touch ${prefix}.junction_saturation.r ${prefix}.geneBodyCoverage.txt
    touch versions.yml
    """
}
