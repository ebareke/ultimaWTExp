// STAR --runMode genomeGenerate — build the STAR index from FASTA + GTF.
// genomeSAindexNbases is auto-scaled to the genome size (STAR's recommended
// min(14, log2(L)/2 - 1)) so the same module works for a tiny synthetic
// "genome" and a full human assembly.
process STAR_GENOMEGENERATE {
    tag   "${fasta.name}"
    label 'process_index'

    input:
    path fasta
    path gtf

    output:
    path "star", emit: index
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def overhang = params.rmats_read_length ? (params.rmats_read_length - 1) : 100
    """
    set -euo pipefail
    mkdir -p star

    genome_len=\$(grep -v '^>' ${fasta} | tr -d '\\n' | wc -c)
    sa_index=\$(awk -v L="\$genome_len" 'BEGIN{ v=int((log(L)/log(2))/2 - 1); if(v>14)v=14; if(v<2)v=2; print v }')

    STAR \\
        --runMode genomeGenerate \\
        --genomeDir star \\
        --genomeFastaFiles ${fasta} \\
        --sjdbGTFfile ${gtf} \\
        --sjdbOverhang ${overhang} \\
        --genomeSAindexNbases \$sa_index \\
        --runThreadN ${task.cpus} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$(STAR --version)
    END_VERSIONS
    """

    stub:
    """
    mkdir -p star
    touch star/Genome star/SA star/SAindex star/genomeParameters.txt star/sjdbList.out.tab
    touch versions.yml
    """
}
