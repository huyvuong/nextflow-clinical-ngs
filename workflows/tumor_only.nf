/*
 * ============================================================================
 *  workflows/tumor_only.nf: Tumor-Only Candidate Somatic Calling (Milestone 5)
 * ============================================================================
 *  Reuses the exact same Mutect2, GetPileupSummaries, CalculateContamination,
 *  and FilterMutectCalls modules as TUMOR_NORMAL by passing empty normal inputs.
 */

include { MUTECT2                } from '../modules/mutect2'
include { GETPILEUPSUMMARIES     } from '../modules/getpileupsummaries'
include { CALCULATECONTAMINATION } from '../modules/calculatecontamination'
include { FILTERMUTECTCALLS      } from '../modules/filtermutectcalls'

workflow TUMOR_ONLY {
    take:
    tumor_bam_ch // tuple val(meta), path(bam), path(bai)
    ref_ch       // tuple path(fasta), path(fai), path(dict)

    main:
    germline_res_ch = channel.value(file(params.germline_resource, checkIfExists: true))
    pon_ch          = channel.value(file(params.pon, checkIfExists: true))

    // Adapt single-sample tuple to the reusable MUTECT2 interface (empty normal lists)
    unpaired_input_ch = tumor_bam_ch.map { meta, bam, bai ->
        tuple(meta, bam, bai, [], [])
    }

    MUTECT2(
        unpaired_input_ch,
        ref_ch,
        germline_res_ch,
        pon_ch
    )

    GETPILEUPSUMMARIES(
        tumor_bam_ch,
        germline_res_ch
    )

    pileup_f1r2_ch = GETPILEUPSUMMARIES.out.table
        .join(MUTECT2.out.f1r2)

    CALCULATECONTAMINATION(pileup_f1r2_ch)

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
