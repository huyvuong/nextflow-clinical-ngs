/*
 * ============================================================================
 *  workflows/tumor_normal.nf: Matched Tumor-Normal Somatic Calling (Milestone 4)
 * ============================================================================
 *  Reuses shared Mutect2 + Contamination + Orientation + FilterMutectCalls modules.
 */

include { MUTECT2                } from '../modules/mutect2'
include { GETPILEUPSUMMARIES     } from '../modules/getpileupsummaries'
include { CALCULATECONTAMINATION } from '../modules/calculatecontamination'
include { FILTERMUTECTCALLS      } from '../modules/filtermutectcalls'

workflow TUMOR_NORMAL {
    take:
    paired_bam_ch // tuple val(meta), path(t_bam), path(t_bai), path(n_bam), path(n_bai)
    ref_ch        // tuple path(fasta), path(fai), path(dict)

    main:
    germline_res_ch = channel.value(file(params.germline_resource, checkIfExists: true))
    pon_ch          = channel.value(file(params.pon, checkIfExists: true))

    MUTECT2(
        paired_bam_ch,
        ref_ch,
        germline_res_ch,
        pon_ch
    )

    // Extract tumor BAM for pileup summaries
    tumor_bam_only_ch = paired_bam_ch.map { meta, t_bam, t_bai, _n_bam, _n_bai ->
        tuple(meta, t_bam, t_bai)
    }

    GETPILEUPSUMMARIES(
        tumor_bam_only_ch,
        germline_res_ch
    )

    // Join pileup table with F1R2 orientation tar.gz by sample meta
    pileup_f1r2_ch = GETPILEUPSUMMARIES.out.table
        .join(MUTECT2.out.f1r2)

    CALCULATECONTAMINATION(pileup_f1r2_ch)

    // Join unfiltered VCF + stats + contamination + orientation artifact priors
    filter_input_ch = MUTECT2.out.vcf
        .join(CALCULATECONTAMINATION.out.contamination)

    FILTERMUTECTCALLS(
        filter_input_ch,
        ref_ch
    )

    ch_versions = MUTECT2.out.versions
        .mix(GETPILEUPSUMMARIES.out.versions)
        .mix(CALCULATECONTAMINATION.out.versions)
        .mix(FILTERMUTECTCALLS.out.versions)

    emit:
    vcf      = FILTERMUTECTCALLS.out.vcf
    qc       = FILTERMUTECTCALLS.out.stats
    versions = ch_versions
}
