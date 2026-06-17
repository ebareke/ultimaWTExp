// dump_software_versions — collect every process's versions.yml into one
// provenance file plus a MultiQC-ingestible table, so each run records the exact
// tool versions used (a reproducibility requirement).
process DUMP_SOFTWARE_VERSIONS {
    label 'process_single'

    input:
    path versions

    output:
    path "software_versions.yml",      emit: yml
    path "software_versions_mqc.yml",  emit: mqc

    script:
    """
    dump_versions.py ${versions} > software_versions.yml

    cat <<-EOF > software_versions_mqc.yml
    id: 'software_versions'
    section_name: 'ultimaWTExp software versions'
    section_href: 'https://github.com/ebareke/ultimaWTExp'
    plot_type: 'html'
    description: 'collected at run time from each process'
    data: |
    \$(dump_versions.py --html ${versions} | sed 's/^/    /')
    EOF
    """

    stub:
    """
    echo "Workflow: {ultimaWTExp: 1.0.0}" > software_versions.yml
    echo "id: software_versions" > software_versions_mqc.yml
    """
}
