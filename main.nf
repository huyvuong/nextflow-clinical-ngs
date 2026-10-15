#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

/*
 * ============================================================================
 *  nextflow-clinical-ngs: Clinical NGS Meta-Pipeline (Nextflow DSL2)
 * ============================================================================
 *  Supports three short-read DNA variant calling modes sharing unified
 *  preprocessing and QC:
 *    1. germline      — Germline SNV/indel calling (GATK HaplotypeCaller GVCF)
 *    2. tumor_normal  — Matched somatic calling (GATK Mutect2 paired)
 *    3. tumor_only    — Unmatched candidate somatic calling (GATK Mutect2)
 *    4. all           — Mixed cohort routing across all three branches
 *
 *  Disclaimer: Research and educational implementation; not a clinically
 *  validated diagnostic workflow.
 * ============================================================================
 */

include { CLINICAL_NGS } from './workflows/clinical_ngs'



workflow {
    // Validate required CLI parameters upfront
    if (!params.input) {
        error "ERROR: Missing required parameter '--input <samplesheet.csv>'."
    }
    if (!params.reference) {
        error "ERROR: Missing required parameter '--reference <reference.fa>'."
    }

    def valid_analyses = ['germline', 'tumor_normal', 'tumor_only', 'all']
    
    if (!(params.analysis in valid_analyses)) {
        error "ERROR: Invalid '--analysis ${params.analysis}'. Allowed values: ${valid_analyses.join(', ')}"
    }

    log.info """
    ========================================================================
     n e x t f l o w - c l i n i c a l - n g s   (v${workflow.manifest.version})
    ========================================================================
     Input samplesheet : ${params.input}
     Analysis mode     : ${params.analysis}
     Reference FASTA   : ${params.reference}
     Run BQSR          : ${params.run_bqsr}
     Output directory  : ${params.outdir}
    ========================================================================
    """.stripIndent()

    // Reference files channel (FASTA + FAI + DICT)
    def ref_fa   = file(params.reference, checkIfExists: true)
    def ref_fai  = file("${params.reference}.fai", checkIfExists: true)
    def ref_dict = file(params.reference.replaceAll(/\.(fa|fasta)$/, '.dict'), checkIfExists: true)
    ref_ch = channel.value(tuple(ref_fa, ref_fai, ref_dict))

    // Raw CSV rows channel
    raw_samples_ch = channel
        .fromPath(params.input, checkIfExists: true)
        .splitCsv(header: true, strip: true)

    CLINICAL_NGS(
        raw_samples_ch,
        ref_ch
    )
}
