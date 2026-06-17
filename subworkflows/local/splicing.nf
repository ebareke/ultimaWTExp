/*
 * splicing — differential alternative splicing with rMATS, one run per contrast.
 * Groups the aligned BAMs into the two condition arms (b1 = reference, b2 =
 * target) using the design's `condition` column, then detects SE/RI/A5SS/A3SS/
 * MXE events between them.
 */

include { RMATS } from '../../modules/local/rmats.nf'

// sample_id -> condition, read from the design on the head node.
def sampleConditionMap() {
    def m = [:]
    if (!params.design) return m
    def lines = file(params.design).readLines()*.trim().findAll { it }
    def header = lines.remove(0).split('\t')*.trim()
    def sidx = header.indexOf('sample_id')
    def cidx = header.indexOf('condition')
    if (sidx < 0 || cidx < 0) return m
    lines.each { def f = it.split('\t'); if (f.size() > Math.max(sidx, cidx)) m[f[sidx].trim()] = f[cidx].trim() }
    return m
}

// Same contrast derivation as DE so splicing arms match the DE comparisons.
def splicingContrasts() {
    if (params.contrasts) {
        def rows = file(params.contrasts).readLines()*.trim().findAll { it && !it.startsWith('#') }
        def header = rows.remove(0).split(',')*.trim()
        return rows.collect { line ->
            def f = line.split(',')*.trim(); def mm = [:]
            header.eachWithIndex { h, i -> mm[h] = f[i] }
            [ id: mm.id, reference: mm.reference, target: mm.target ]
        }
    }
    def cond = sampleConditionMap()
    def levels = cond.values().toList().unique().sort()
    if (levels.size() < 2) return []
    def reference = levels[0]
    return levels.drop(1).collect { [ id: "${it}_vs_${reference}", reference: reference, target: it ] }
}

workflow SPLICING {

    take:
    ch_bam_bai        // tuple(meta, bam, bai)
    ch_gtf

    main:
    ch_versions = Channel.empty()

    def cond      = sampleConditionMap()
    def contrasts = splicingContrasts()

    // Collect all (sample_id, bam) pairs into one emission, then build the two
    // arms per contrast. combine() would flatten the pair-list into the tuple,
    // so derive the groups inside a single map and flatMap them out instead.
    ch_rmats_in = ch_bam_bai
        .map { meta, bam, bai -> [ meta.id, bam ] }
        .toList()
        .flatMap { bamlist ->
            contrasts.collect { c ->
                def b1 = bamlist.findAll { cond[it[0]] == c.reference }.collect { it[1] }
                def b2 = bamlist.findAll { cond[it[0]] == c.target    }.collect { it[1] }
                [ c.id, b1, b2 ]
            }
        }
        .filter { id, b1, b2 -> b1.size() > 0 && b2.size() > 0 }

    RMATS( ch_rmats_in, ch_gtf )
    ch_versions = ch_versions.mix( RMATS.out.versions.first() )

    emit:
    results  = RMATS.out.results
    versions = ch_versions
}
