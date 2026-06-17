// FastQC — per-read-file quality control. Handles SE/PE via the staged reads.
// Imported twice (FASTQC_RAW, FASTQC_TRIM) so raw and post-trim reports are
// kept in separate output folders (see conf/modules.config).
process FASTQC {
    tag   "${meta.id}"
    label 'process_medium'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.zip"),  emit: zip
    tuple val(meta), path("*.html"), emit: html
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: meta.id
    // Rename staged reads to stable, sample-prefixed names so the FastQC
    // report titles are deterministic regardless of the original filenames.
    def renamed = reads.withIndex().collect { f, i ->
        def suffix = meta.single_end ? '' : "_${i + 1}"
        "ln -sf ${f} ${prefix}${suffix}.fastq.gz"
    }.join('\n    ')
    """
    ${renamed}
    fastqc --threads ${task.cpus} --quiet ${prefix}*.fastq.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqc: \$(fastqc --version | sed 's/^FastQC v//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: meta.id
    def names  = meta.single_end ? ["${prefix}"] : ["${prefix}_1", "${prefix}_2"]
    """
    ${names.collect { "touch ${it}_fastqc.zip ${it}_fastqc.html" }.join('\n    ')}
    touch versions.yml
    """
}
