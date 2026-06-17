// render_report — render a Quarto/RMarkdown template to a self-contained HTML
// report. Called once per audience (executive, technical, QC, differential)
// with the relevant result files staged under ./data. Falls back to R Markdown
// if Quarto is unavailable so the dependency stays soft.
process RENDER_REPORT {
    tag   "${report_name}"
    label 'process_low'

    input:
    tuple val(report_name), path(template)
    path  ("data/*")

    output:
    path "*.html", emit: report
    path "versions.yml", emit: versions

    script:
    """
    set -euo pipefail
    export XDG_CACHE_HOME=\$PWD/.cache

    if command -v quarto >/dev/null 2>&1 && [[ "${template}" == *.qmd ]]; then
        quarto render ${template} \\
            -P data_dir:data -P outdir:${params.outdir} -P run_id:${workflow.runName} \\
            --output ${report_name}.html
    else
        Rscript -e "rmarkdown::render('${template}', output_file='${report_name}.html', \\
            params=list(data_dir='data', outdir='${params.outdir}'), \\
            knit_root_dir=getwd(), output_dir=getwd())"
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        quarto: \$(quarto --version 2>/dev/null || echo NA)
    END_VERSIONS
    """

    stub:
    """
    echo "<html><body><h1>${report_name} report (stub)</h1></body></html>" > ${report_name}.html
    touch versions.yml
    """
}
