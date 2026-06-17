// hisat2-build — build a splice-aware HISAT2 index, extracting splice sites and
// exons from the GTF so the index is transcriptome-aware.
process HISAT2_BUILD {
    tag   "${fasta.name}"
    label 'process_index'

    input:
    path fasta
    path gtf

    output:
    path "hisat2", emit: index
    path "versions.yml", emit: versions

    script:
    """
    set -euo pipefail
    mkdir -p hisat2

    hisat2_extract_splice_sites.py ${gtf} > hisat2/splice_sites.txt
    hisat2_extract_exons.py        ${gtf} > hisat2/exons.txt

    hisat2-build \\
        -p ${task.cpus} \\
        --ss hisat2/splice_sites.txt \\
        --exon hisat2/exons.txt \\
        ${fasta} \\
        hisat2/${fasta.baseName}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hisat2: \$(hisat2 --version | head -n1 | sed 's/^.*version //')
    END_VERSIONS
    """

    stub:
    """
    mkdir -p hisat2
    for i in 1 2 3 4 5 6 7 8; do touch hisat2/${fasta.baseName}.\$i.ht2; done
    touch versions.yml
    """
}
