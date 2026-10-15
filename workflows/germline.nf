/*
 * ============================================================================
 *  workflows/germline.nf: Germline SNV/Indel Calling Subworkflow (Milestone 3)
 * ============================================================================
 *  HaplotypeCaller (GVCF mode) -> GenotypeGVCFs + Hard Filtering -> VCF.gz
 */

include { HAPLOTYPECALLER } from '../modules/haplotypecaller'
include { GENOTYPEGVCFS   } from '../modules/genotypegvcfs'

workflow GERMLINE {
    take:
    germline_bam_ch // tuple val(meta), path(bam), path(bai)
    ref_ch          // tuple path(fasta), path(fai), path(dict)

    main:
    HAPLOTYPECALLER(germline_bam_ch, ref_ch)
    GENOTYPEGVCFS(HAPLOTYPECALLER.out.gvcf, ref_ch)

    ch_versions = HAPLOTYPECALLER.out.versions.mix(GENOTYPEGVCFS.out.versions)

    emit:
    vcf      = GENOTYPEGVCFS.out.vcf
    qc       = GENOTYPEGVCFS.out.stats
    versions = ch_versions
}
