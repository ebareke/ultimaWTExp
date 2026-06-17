// salmon index — decoy-aware transcriptome index. The transcript FASTA is
// extracted from genome+GTF with gffread (unless supplied), and the genome
// contigs are added as decoys so Salmon can discount spurious genomic matches.
// Also emits transcripts.fa and tx2gene.tsv for downstream tximport.
process SALMON_INDEX {
    tag   "salmon"
    label 'process_index'

    input:
    path genome_fasta
    path transcript_fasta   // may be a placeholder named 'NO_TRANSCRIPTS'
    path gtf

    output:
    path "salmon",          emit: index
    path "transcripts.fa",  emit: transcripts
    path "tx2gene.tsv",     emit: tx2gene
    path "versions.yml",    emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    set -euo pipefail

    if [ "${transcript_fasta.name}" != "NO_TRANSCRIPTS" ]; then
        cp ${transcript_fasta} transcripts.fa
    else
        gffread -w transcripts.fa -g ${genome_fasta} ${gtf}
    fi

    # transcript_id -> gene_id (-> gene_name) for tximport.
    awk -F '\\t' '\$3 == "transcript" || \$3 == "exon" {
        match(\$9, /transcript_id "[^"]+"/); tid=substr(\$9,RSTART+15,RLENGTH-16);
        match(\$9, /gene_id "[^"]+"/);       gid=substr(\$9,RSTART+9,RLENGTH-10);
        gn=gid; if (match(\$9, /gene_name "[^"]+"/)) gn=substr(\$9,RSTART+11,RLENGTH-12);
        if (tid != "" && !(tid in seen)) { print tid"\\t"gid"\\t"gn; seen[tid]=1 }
    }' ${gtf} > tx2gene.tsv

    # Decoy-aware index: genome contigs as decoys appended to the transcriptome.
    grep '^>' ${genome_fasta} | sed 's/^>//' | cut -d ' ' -f1 > decoys.txt
    cat transcripts.fa ${genome_fasta} > gentrome.fa

    salmon index \\
        --threads ${task.cpus} \\
        -t gentrome.fa \\
        -d decoys.txt \\
        -i salmon \\
        -k 31 \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        salmon: \$(salmon --version | sed 's/salmon //')
    END_VERSIONS
    """

    stub:
    """
    mkdir -p salmon
    touch salmon/info.json salmon/pos.bin salmon/ctable.bin
    touch transcripts.fa
    printf 'tx1\\tgene1\\tGENE1\\ntx2\\tgene2\\tGENE2\\n' > tx2gene.tsv
    touch versions.yml
    """
}
