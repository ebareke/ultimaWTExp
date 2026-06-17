// gffread — convert GFF3 to GTF when only a GFF is supplied.
process GFFREAD {
    tag   "${gff.name}"
    label 'process_single'

    input:
    path gff

    output:
    path "*.gtf", emit: gtf
    path "versions.yml", emit: versions

    script:
    def prefix = gff.baseName
    """
    gffread ${gff} --keep-exon-attrs -F -T -o ${prefix}.gtf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gffread: \$(gffread --version 2>&1)
    END_VERSIONS
    """

    stub:
    def prefix = gff.baseName
    """
    touch ${prefix}.gtf
    touch versions.yml
    """
}
