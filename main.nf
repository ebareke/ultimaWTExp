#!/usr/bin/env nextflow
/*
 * ===========================================================================
 * ultimaWTExp — Research-lab RNA-seq analysis platform
 * End-to-end: FASTQ -> QC -> trim -> align -> quantify -> fusion -> splicing
 *             -> differential expression -> functional enrichment -> reports
 *
 * Homepage : https://ebareke.github.io/ultimaWTExp/
 * Authors  : Eric Bareke, Ethan M., Conrad B.   (MIT licensed)
 * ===========================================================================
 */

nextflow.enable.dsl = 2

include { RNASEQ } from './workflows/rnaseq.nf'

// ---------------------------------------------------------------------------
// Console helpers
// ---------------------------------------------------------------------------
def banner() {
    def v = workflow.manifest.version
    return """\
    -\033[2m----------------------------------------------------\033[0m-
        \033[0;32m╦ ╦╦ ╔╦╗╦╔╦╗╔═╗\033[0m  \033[0;34mW T E x p\033[0m
        \033[0;32m║ ║║  ║ ║║║║╠═╣\033[0m  RNA-seq analysis platform
        \033[0;32m╚═╝╩═╝╩ ╩╩ ╩╩ ╩\033[0m  v${v}
    -\033[2m----------------------------------------------------\033[0m-
    """.stripIndent()
}

def helpMessage() {
    log.info banner()
    log.info """
    Usage:
      nextflow run ebareke/ultimaWTExp --input samplesheet.csv --design sample_design.tsv \\
          --fasta genome.fa --gtf genes.gtf --organism human -profile docker

    Mandatory:
      --input            Samplesheet CSV (sample_id,fastq_1,fastq_2,strandedness)
      --fasta            Genome FASTA (.fa/.fa.gz)
      --gtf              Gene annotation GTF (or --gff)

    Common options:
      --design           sample_design.tsv driving differential expression
      --organism         human | mouse | rat | custom            [custom]
      --aligner          star | hisat2 | star_hisat2             [star]
      --pseudo_aligner   salmon | null                           [salmon]
      --gene_quant       featurecounts | htseq | star            [featurecounts]
      --trimmer          fastp | trimgalore | cutadapt | none    [fastp]
      --outdir           Output directory                        [results]
      -profile           docker,singularity,apptainer,conda + local,slurm,pbs,lsf,sge

    Toggles:
      --run_fusion / --run_splicing / --run_dge / --run_enrichment / --run_gsea
      --skip_fastqc / --skip_qualimap / --skip_rseqc / --skip_picard / --skip_multiqc

    Use --help to show this message, --version to print the version.
    Full reference: docs/USAGE.md
    """.stripIndent()
}

// ---------------------------------------------------------------------------
// Parameter validation — fail fast, before any compute is scheduled.
// ---------------------------------------------------------------------------
def validateParameters() {
    def errors = []

    if (!params.input)  errors << "Missing --input (samplesheet CSV)."
    if (!params.fasta && !params.genome)
        errors << "Missing reference: provide --fasta (+ --gtf) or a --genome key."
    if (!params.gtf && !params.gff && params.fasta)
        errors << "Missing annotation: provide --gtf or --gff alongside --fasta."

    def aligners = ['star', 'hisat2', 'star_hisat2']
    if (!(params.aligner in aligners))
        errors << "--aligner must be one of ${aligners} (got '${params.aligner}')."

    def trimmers = ['fastp', 'trimgalore', 'cutadapt', 'none']
    if (!(params.trimmer in trimmers))
        errors << "--trimmer must be one of ${trimmers} (got '${params.trimmer}')."

    def quants = ['featurecounts', 'htseq', 'star']
    if (!(params.gene_quant in quants))
        errors << "--gene_quant must be one of ${quants} (got '${params.gene_quant}')."

    def strands = ['auto', 'unstranded', 'forward', 'reverse']
    if (!(params.strandedness in strands))
        errors << "--strandedness must be one of ${strands} (got '${params.strandedness}')."

    def organisms = ['human', 'mouse', 'rat', 'custom']
    if (!(params.organism in organisms))
        errors << "--organism must be one of ${organisms} (got '${params.organism}')."

    if (params.run_fusion && params.aligner == 'hisat2')
        errors << "--run_fusion requires STAR (set --aligner star or star_hisat2)."

    if (params.run_enrichment && params.organism == 'custom' && !params.gsea_gmt)
        log.warn "Enrichment requested with --organism custom and no --gsea_gmt: ID-based ORA/GSEA will be skipped."

    if (errors) {
        log.error "Parameter validation failed:\n  - " + errors.join('\n  - ')
        System.exit(1)
    }
}

// ---------------------------------------------------------------------------
// Build the (meta, [reads]) channel from the samplesheet.
// Columns: sample_id, fastq_1, fastq_2 (optional), strandedness (optional).
// ---------------------------------------------------------------------------
def buildReadChannel() {
    Channel
        .fromPath(params.input, checkIfExists: true)
        .splitCsv(header: true, strip: true)
        .map { row ->
            if (!row.sample_id) error "Samplesheet row missing 'sample_id': ${row}"
            if (!row.fastq_1)   error "Samplesheet row '${row.sample_id}' missing 'fastq_1'."

            def has_r2      = row.fastq_2 && row.fastq_2.trim()
            def strand      = (row.strandedness && row.strandedness.trim()) ? row.strandedness.trim() : params.strandedness
            def meta        = [ id: row.sample_id, single_end: !has_r2, strandedness: strand ]
            def reads       = has_r2
                              ? [ file(row.fastq_1, checkIfExists: true), file(row.fastq_2, checkIfExists: true) ]
                              : [ file(row.fastq_1, checkIfExists: true) ]
            tuple(meta, reads)
        }
}

// ---------------------------------------------------------------------------
// Entry workflow
// ---------------------------------------------------------------------------
workflow {

    if (params.help)    { helpMessage();             return }
    if (params.version) { log.info "ultimaWTExp ${workflow.manifest.version}"; return }

    log.info banner()

    if (params.validate_params) validateParameters()

    ch_reads = buildReadChannel()

    RNASEQ(ch_reads)
}

workflow.onComplete {
    def status = workflow.success ? "\033[0;32mSUCCESS\033[0m" : "\033[0;31mFAILED\033[0m"
    log.info """
    -\033[2m----------------------------------------------------\033[0m-
    ultimaWTExp run complete: ${status}
      Duration : ${workflow.duration}
      Results  : ${params.outdir}
      Reports  : ${params.outdir}/reports , ${params.outdir}/multiqc
      Provenance: ${params.tracedir}
    -\033[2m----------------------------------------------------\033[0m-
    """.stripIndent()
}

workflow.onError {
    log.error "Pipeline stopped: ${workflow.errorMessage}"
}
