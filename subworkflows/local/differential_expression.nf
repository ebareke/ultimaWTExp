/*
 * differential_expression — metadata-driven DE. Builds the set of contrasts
 * (from an explicit --contrasts CSV, or auto-derived from the design's
 * `condition` factor levels) and runs DESeq2 (always) and edgeR (optional) for
 * each. Each contrast = [id, variable, reference, target].
 */

include { DESEQ2 } from '../../modules/local/deseq2.nf'
include { EDGER  } from '../../modules/local/edger.nf'

// ---------------------------------------------------------------------------
// Read the contrast definitions on the head node, before scheduling.
//   - explicit:  --contrasts CSV  (id,variable,reference,target)
//   - automatic: every non-reference level of `condition` vs the first level
// Returns a List<Map>.
// ---------------------------------------------------------------------------
def readContrasts() {
    if (params.contrasts) {
        def rows = file(params.contrasts).readLines()*.trim().findAll { it && !it.startsWith('#') }
        def header = rows.remove(0).split(',')*.trim()
        return rows.collect { line ->
            def f = line.split(',')*.trim()
            def m = [:]; header.eachWithIndex { h, i -> m[h] = f[i] }
            [ id: m.id, variable: m.variable, reference: m.reference, target: m.target ]
        }
    }

    // Auto: derive from the design's `condition` column.
    def lines = file(params.design).readLines()*.trim().findAll { it }
    def header = lines.remove(0).split('\t')*.trim()
    def cidx = header.indexOf('condition')
    if (cidx < 0) {
        log.warn "No --contrasts and no 'condition' column in design — skipping DE."
        return []
    }
    def levels = lines.collect { it.split('\t')[cidx]?.trim() }.findAll { it }.unique().sort()
    if (levels.size() < 2) {
        log.warn "design 'condition' has < 2 levels — skipping DE."
        return []
    }
    def reference = levels[0]
    return levels.drop(1).collect { lvl ->
        [ id: "${lvl}_vs_${reference}", variable: 'condition', reference: reference, target: lvl ]
    }
}

workflow DIFFERENTIAL_EXPRESSION {

    take:
    ch_counts_raw     // single gene count matrix

    main:
    ch_versions = Channel.empty()

    def contrasts = readContrasts()
    if (contrasts) {
        log.info "Differential expression contrasts: " + contrasts.collect { it.id }.join(', ')
    }

    ch_contrasts = Channel.fromList(contrasts)
    ch_de_input  = ch_contrasts
        .combine( ch_counts_raw )
        .map { c, counts -> tuple(c, counts, file(params.design, checkIfExists: true)) }

    DESEQ2( ch_de_input )
    ch_de_results = DESEQ2.out.results
    ch_versions   = ch_versions.mix( DESEQ2.out.versions.first() )

    if (params.run_edger) {
        EDGER( ch_de_input )
        ch_versions = ch_versions.mix( EDGER.out.versions.first() )
    }

    emit:
    de_results = ch_de_results       // tuple(contrast, results.tsv)
    versions   = ch_versions
}
