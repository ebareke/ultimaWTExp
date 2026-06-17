// checksums — SHA-256 over the primary deliverables (count matrices, DE tables,
// reports). Lets a downstream consumer verify byte-for-byte that they received
// exactly what the pipeline produced (reproducibility / auditability).
process CHECKSUMS {
    label 'process_single'

    input:
    path deliverables

    output:
    path "SHA256SUMS.txt", emit: checksums

    script:
    """
    sha256sum ${deliverables} | sort -k2 > SHA256SUMS.txt
    """

    stub:
    """
    echo "0000000000000000000000000000000000000000000000000000000000000000  stub" > SHA256SUMS.txt
    """
}
