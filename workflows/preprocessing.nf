/*
 * ============================================================================
 *  workflows/preprocessing.nf: Shared FASTQ-to-BAM Preprocessing Subworkflow
 * ============================================================================
 *  Reused across germline, tumor-normal, and tumor-only samples.
 */

include { FASTQC                           } from '../modules/fastqc'
include { FASTP                            } from '../modules/fastp'
include { BWA_MEM2                         } from '../modules/bwa_mem2'
include { SAMTOOLS_SORT                    } from '../modules/samtools_sort'
include { MARKDUPLICATES                   } from '../modules/markduplicates'
include { SAMTOOLS_INDEX as INDEX_MARKDUP  } from '../modules/samtools_index'
include { BQSR                             } from '../modules/bqsr'
include { SAMTOOLS_INDEX as INDEX_BQSR     } from '../modules/samtools_index'

workflow PREPROCESSING {
    take:
    samples_ch // tuple val(meta), path(reads)
    ref_ch     // tuple path(fasta), path(fai), path(dict)

    main:
    ch_versions = channel.empty()
    ch_qc       = channel.empty()

    FASTQC(samples_ch)
    ch_qc       = ch_qc.mix(FASTQC.out.zip)
    ch_versions = ch_versions.mix(FASTQC.out.versions)

    FASTP(samples_ch)
    ch_qc       = ch_qc.mix(FASTP.out.json)
    ch_versions = ch_versions.mix(FASTP.out.versions)

    BWA_MEM2(FASTP.out.reads, ref_ch)
    ch_versions = ch_versions.mix(BWA_MEM2.out.versions)

    SAMTOOLS_SORT(BWA_MEM2.out.sam)
    ch_versions = ch_versions.mix(SAMTOOLS_SORT.out.versions)

    MARKDUPLICATES(SAMTOOLS_SORT.out.bam)
    ch_qc       = ch_qc.mix(MARKDUPLICATES.out.metrics)
    ch_versions = ch_versions.mix(MARKDUPLICATES.out.versions)

    INDEX_MARKDUP(MARKDUPLICATES.out.bam)
    ch_qc       = ch_qc.mix(INDEX_MARKDUP.out.flagstat)
    ch_versions = ch_versions.mix(INDEX_MARKDUP.out.versions)

    // Configurable BQSR (Milestone 2)
    if (params.run_bqsr && params.known_sites) {
        known_sites_ch = channel.value(file(params.known_sites, checkIfExists: true))
        BQSR(INDEX_MARKDUP.out.bam_bai, ref_ch, known_sites_ch)
        INDEX_BQSR(BQSR.out.bam)
        final_bam_ch = INDEX_BQSR.out.bam_bai
        ch_qc        = ch_qc.mix(BQSR.out.table)
        ch_versions  = ch_versions.mix(BQSR.out.versions)
    } else {
        final_bam_ch = INDEX_MARKDUP.out.bam_bai
    }

    emit:
    bam      = final_bam_ch // tuple val(meta), path(bam), path(bai)
    qc       = ch_qc
    versions = ch_versions
}
