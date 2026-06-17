// gunzip — decompress a single gzipped reference file (FASTA/GTF/GFF).
// No-op pass-through if the input is already uncompressed.
process GUNZIP {
    tag    "${archive.name}"
    label  'process_single'

    input:
    path archive

    output:
    path "$gunzip", emit: gunzip
    path "versions.yml", emit: versions

    script:
    gunzip = archive.name.replaceAll(/\.gz$/, '')
    """
    if [ "${archive}" != "${gunzip}" ]; then
        gzip -cd ${archive} > ${gunzip}
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gunzip: \$(echo \$(gzip --version 2>&1 | head -n1 | sed 's/^.* //'))
    END_VERSIONS
    """

    stub:
    gunzip = archive.name.replaceAll(/\.gz$/, '')
    """
    touch ${gunzip}
    touch versions.yml
    """
}
