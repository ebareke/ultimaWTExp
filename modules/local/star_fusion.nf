// STAR-Fusion — gene-fusion detection from STAR's Chimeric.out.junction against
// a CTAT genome library. Emits the ranked fusion-candidate table and its
// abridged/coding-effect companions.
process STAR_FUSION {
    tag   "${meta.id}"
    label 'process_high'

    input:
    tuple val(meta), path(junction)
    path  ctat_lib

    output:
    tuple val(meta), path("*.fusion_predictions.tsv"),           emit: fusions
    tuple val(meta), path("*.fusion_predictions.abridged.tsv"),  emit: abridged, optional: true
    path "versions.yml", emit: versions

    script:
    def prefix = meta.id
    """
    STAR-Fusion \\
        --genome_lib_dir ${ctat_lib} \\
        -J ${junction} \\
        --CPU ${task.cpus} \\
        --output_dir starfusion_out

    cp starfusion_out/star-fusion.fusion_predictions.tsv          ${prefix}.fusion_predictions.tsv
    cp starfusion_out/star-fusion.fusion_predictions.abridged.tsv ${prefix}.fusion_predictions.abridged.tsv || true

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star-fusion: \$(STAR-Fusion --version 2>&1 | grep -o '[0-9.]*' | head -n1 || echo NA)
    END_VERSIONS
    """

    stub:
    def prefix = meta.id
    """
    printf '#FusionName\\tJunctionReadCount\\tSpanningFragCount\\n' > ${prefix}.fusion_predictions.tsv
    printf '#FusionName\\tJunctionReadCount\\tSpanningFragCount\\n' > ${prefix}.fusion_predictions.abridged.tsv
    touch versions.yml
    """
}
