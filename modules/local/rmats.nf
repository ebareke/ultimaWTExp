// rMATS turbo — replicate-aware differential alternative splicing between two
// condition groups. Detects all five event classes (SE, RI, A5SS, A3SS, MXE)
// and emits per-event statistical tables (JC + JCEC).
process RMATS {
    tag   "${contrast}"
    label 'process_high'

    input:
    tuple val(contrast), path(b1_bams), path(b2_bams)
    path  gtf

    output:
    tuple val(contrast), path("${contrast}_rmats/*.txt"), emit: results, optional: true
    tuple val(contrast), path("${contrast}_rmats/summary.txt"), emit: summary, optional: true
    path "versions.yml", emit: versions

    script:
    def readlen = params.rmats_read_length
    def variable = params.rmats_variable_read_length ? '--variable-read-length' : ''
    def novel    = params.rmats_novel_ss ? '--novelSS' : ''
    def libtype  = 'fr-unstranded'
    """
    set -euo pipefail
    ls ${b1_bams} | paste -sd, - > b1.txt
    ls ${b2_bams} | paste -sd, - > b2.txt

    rmats.py \\
        --b1 b1.txt --b2 b2.txt \\
        --gtf ${gtf} \\
        -t paired \\
        --readLength ${readlen} ${variable} ${novel} \\
        --libType ${libtype} \\
        --nthread ${task.cpus} \\
        --od ${contrast}_rmats \\
        --tmp ${contrast}_tmp

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rmats: \$(rmats.py --version 2>&1 | sed 's/^v//' || echo NA)
    END_VERSIONS
    """

    stub:
    """
    mkdir -p ${contrast}_rmats
    for e in SE RI A5SS A3SS MXE; do
        printf 'ID\\tGeneID\\tPValue\\tFDR\\tIncLevelDifference\\n' > ${contrast}_rmats/\${e}.MATS.JC.txt
    done
    printf 'EventType\\tSignificant\\nSE\\t0\\n' > ${contrast}_rmats/summary.txt
    touch versions.yml
    """
}
