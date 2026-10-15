/*
 * ============================================================================
 *  workflows/reporting.nf: Variant Annotation (VEP) & MultiQC Reporting
 * ============================================================================
 */

include { VEP     } from '../modules/vep'
include { MULTIQC } from '../modules/multiqc'

workflow REPORTING {
    take:
    vcf_ch      // tuple val(meta), path(vcf), path(tbi)
    qc_ch       // path(qc_files)
    versions_ch // path(versions_yml)
    ref_ch      // tuple path(fasta), path(fai), path(dict)

    main:
    VEP(vcf_ch, ref_ch)

    all_multiqc_files_ch = qc_ch
        .mix(VEP.out.summary)
        .collect()

    versions_ch
        .mix(VEP.out.versions)
        .unique()
        .collectFile(name: 'software_versions.yml', storeDir: "${params.outdir}/pipeline_info")

    MULTIQC(all_multiqc_files_ch)

    emit:
    annotated_vcf  = VEP.out.vcf
    multiqc_report = MULTIQC.out.report
}
