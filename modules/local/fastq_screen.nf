// FastQ Screen — optional contamination screen against a panel of genomes.
// Requires a prebuilt config pointing at the screen databases (--fastq_screen_conf);
// off by default since those DBs are large and site-specific.
process FASTQ_SCREEN {
    tag   "${meta.id}"
    label 'process_medium'

    input:
    tuple val(meta), path(reads)
    path  screen_conf

    output:
    tuple val(meta), path("*screen.txt"), emit: txt
    tuple val(meta), path("*screen.html"), emit: html, optional: true
    path "versions.yml", emit: versions

    script:
    """
    fastq_screen \\
        --conf ${screen_conf} \\
        --threads ${task.cpus} \\
        --aligner bowtie2 \\
        ${reads}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastq_screen: \$(fastq_screen --version | sed 's/^.*v//')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}_screen.txt
    touch versions.yml
    """
}
