// reference_check — validate that the FASTA and GTF are mutually consistent
// (shared sequence names, non-empty, parseable) and record provenance
// checksums BEFORE any indexing/alignment is attempted. Fails fast on a
// mismatched genome/annotation pair, the single most common silent RNA-seq
// error (everything "runs" but every gene gets zero counts).
process REFERENCE_CHECK {
    tag   "${fasta.name}"
    label 'process_single'

    input:
    path fasta
    path gtf

    output:
    path "reference_report.txt", emit: report
    path "reference.md5",        emit: checksums
    path "versions.yml",         emit: versions

    script:
    """
    set -euo pipefail

    # Contigs present in each file.
    grep '^>' ${fasta} | sed 's/^>//' | awk '{print \$1}' | sort -u > fasta_contigs.txt
    awk -F '\\t' '\$0 !~ /^#/ {print \$1}' ${gtf} | sort -u                > gtf_contigs.txt

    n_fasta=\$(wc -l < fasta_contigs.txt)
    n_gtf=\$(wc -l < gtf_contigs.txt)
    n_shared=\$(comm -12 fasta_contigs.txt gtf_contigs.txt | wc -l | tr -d ' ')
    n_genes=\$(awk -F '\\t' '\$3 == "gene"' ${gtf} | wc -l | tr -d ' ')

    {
      echo "ultimaWTExp reference validation"
      echo "================================="
      echo "FASTA            : ${fasta}"
      echo "GTF              : ${gtf}"
      echo "FASTA contigs    : \$n_fasta"
      echo "GTF  contigs     : \$n_gtf"
      echo "Shared contigs   : \$n_shared"
      echo "Annotated genes  : \$n_genes"
    } > reference_report.txt

    if [ "\$n_shared" -eq 0 ]; then
        echo "ERROR: FASTA and GTF share no sequence names — genome/annotation mismatch." >&2
        cat reference_report.txt >&2
        exit 1
    fi
    if [ "\$n_genes" -eq 0 ]; then
        echo "ERROR: GTF contains no 'gene' features." >&2
        exit 1
    fi

    md5sum ${fasta} ${gtf} > reference.md5

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        coreutils: \$(awk --version 2>/dev/null | head -n1 | sed 's/^.* //' || echo NA)
    END_VERSIONS
    """

    stub:
    """
    echo "stub reference report" > reference_report.txt
    echo "0  stub" > reference.md5
    touch versions.yml
    """
}
