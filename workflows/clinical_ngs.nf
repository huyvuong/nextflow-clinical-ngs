/*
 * ============================================================================
 *  workflows/clinical_ngs.nf: Central DSL2 Meta-Pipeline Orchestrator
 * ============================================================================
 */

include { PREPROCESSING } from './preprocessing'
include { GERMLINE      } from './germline'
include { TUMOR_NORMAL  } from './tumor_normal'
include { TUMOR_ONLY    } from './tumor_only'
include { REPORTING     } from './reporting'

/*
 * Subworkflow: VALIDATE_SAMPLES
 * Validates samplesheet rows, roles, FASTQ file existence/size, and paired normal requirements.
 */
workflow VALIDATE_SAMPLES {
    take:
    raw_rows_ch

    main:
    // Filter by requested analysis mode unless 'all'
    filtered_rows_ch = raw_rows_ch.filter { row ->
        params.analysis == 'all' || row.analysis == params.analysis
    }

    // Validate individual sample schema and construct normalized [meta, [fastq_1, fastq_2]]
    validated_samples_ch = filtered_rows_ch.map { row ->
        if (!row.sample_id || !row.patient_id || !row.analysis || !row.role || !row.fastq_1 || !row.fastq_2) {
            error "Validation Error: Samplesheet row is missing required columns (sample_id,patient_id,analysis,role,fastq_1,fastq_2): ${row}"
        }

        def valid_modes = ['germline', 'tumor_normal', 'tumor_only']
        if (!(row.analysis in valid_modes)) {
            error "Validation Error: Sample '${row.sample_id}' has unsupported analysis '${row.analysis}'."
        }

        if (row.analysis == 'germline' && row.role != 'normal') {
            error "Validation Error: Germline sample '${row.sample_id}' must have role 'normal' (found '${row.role}')."
        }
        if (row.analysis == 'tumor_only' && row.role != 'tumor') {
            error "Validation Error: Tumor-only sample '${row.sample_id}' must have role 'tumor' (found '${row.role}')."
        }
        if (row.analysis == 'tumor_normal' && !(row.role in ['tumor', 'normal'])) {
            error "Validation Error: Tumor-normal sample '${row.sample_id}' must have role 'tumor' or 'normal' (found '${row.role}')."
        }

        def fq1 = file(row.fastq_1, checkIfExists: true)
        def fq2 = file(row.fastq_2, checkIfExists: true)
        if (fq1.size() == 0 || fq2.size() == 0) {
            error "Validation Error: Empty FASTQ file detected for sample '${row.sample_id}'."
        }

        // Support optional pair_id column to disambiguate multiple tumors per patient
        def pair_key = row.containsKey('pair_id') && row.pair_id ? row.pair_id : row.patient_id

        def meta = [
            id        : row.sample_id,
            patient_id: row.patient_id,
            pair_id   : pair_key,
            analysis  : row.analysis,
            role      : row.role
        ]
        tuple(meta, [fq1, fq2])
    }

    // Group-level validation for tumor_normal pairing completeness
    validated_samples_ch
        .filter { meta, _reads -> meta.analysis == 'tumor_normal' }
        .map { meta, _reads -> tuple(meta.pair_id, meta) }
        .groupTuple()
        .subscribe { pair_id, metas ->
            def tumors  = metas.findAll { meta -> meta.role == 'tumor' }
            def normals = metas.findAll { meta -> meta.role == 'normal' }
            if (tumors.isEmpty() || normals.isEmpty()) {
                error "Pairing Error: Patient/Pair '${pair_id}' in 'tumor_normal' mode requires both a 'tumor' and a 'normal' sample. Found tumors=${tumors*.id}, normals=${normals*.id}."
            }
        }

    emit:
    samples = validated_samples_ch
}

/*
 * Subworkflow: ROUTE_SAMPLES
 * Routes preprocessed BAM tuples into germline, paired tumor_normal, and tumor_only channels.
 */
workflow ROUTE_SAMPLES {
    take:
    bam_ch // tuple val(meta), path(bam), path(bai)

    main:
    branched = bam_ch.branch { meta, _bam, _bai ->
        germline:     meta.analysis == 'germline'
        tumor_normal: meta.analysis == 'tumor_normal'
        tumor_only:   meta.analysis == 'tumor_only'
    }

    // Pair matched tumor and normal BAMs by pair_id (defaults to patient_id)
    tn_paired_ch = branched.tumor_normal
        .map { meta, bam, bai -> tuple(meta.pair_id, meta, bam, bai) }
        .groupTuple()
        .map { pair_id, metas, bams, bais ->
            def t_idx = metas.findIndexOf { meta -> meta.role == 'tumor' }
            def n_idx = metas.findIndexOf { meta -> meta.role == 'normal' }
            if (t_idx == -1 || n_idx == -1) {
                error "Routing Error: Incomplete tumor-normal pair for '${pair_id}'."
            }
            def pair_meta = [
                id        : pair_id,
                patient_id: metas[t_idx].patient_id,
                tumor_id  : metas[t_idx].id,
                normal_id : metas[n_idx].id,
                analysis  : 'tumor_normal',
                role      : 'paired'
            ]
            tuple(pair_meta, bams[t_idx], bais[t_idx], bams[n_idx], bais[n_idx])
        }

    emit:
    germline     = branched.germline
    tumor_normal = tn_paired_ch
    tumor_only   = branched.tumor_only
}

/*
 * Main Meta-Pipeline Workflow: CLINICAL_NGS
 */
workflow CLINICAL_NGS {
    take:
    raw_samples_ch
    ref_ch

    main:
    VALIDATE_SAMPLES(raw_samples_ch)

    PREPROCESSING(
        VALIDATE_SAMPLES.out.samples,
        ref_ch
    )

    ROUTE_SAMPLES(PREPROCESSING.out.bam)

    GERMLINE(
        ROUTE_SAMPLES.out.germline,
        ref_ch
    )

    TUMOR_NORMAL(
        ROUTE_SAMPLES.out.tumor_normal,
        ref_ch
    )

    TUMOR_ONLY(
        ROUTE_SAMPLES.out.tumor_only,
        ref_ch
    )

    // Combine all filtered VCFs and QC artifacts for unified annotation & MultiQC reporting
    all_vcfs_ch = GERMLINE.out.vcf
        .mix(TUMOR_NORMAL.out.vcf)
        .mix(TUMOR_ONLY.out.vcf)

    all_qc_ch = PREPROCESSING.out.qc
        .mix(GERMLINE.out.qc)
        .mix(TUMOR_NORMAL.out.qc)
        .mix(TUMOR_ONLY.out.qc)

    all_versions_ch = PREPROCESSING.out.versions
        .mix(GERMLINE.out.versions)
        .mix(TUMOR_NORMAL.out.versions)
        .mix(TUMOR_ONLY.out.versions)

    REPORTING(
        all_vcfs_ch,
        all_qc_ch,
        all_versions_ch,
        ref_ch
    )

    emit:
    germline_vcf     = GERMLINE.out.vcf
    tumor_normal_vcf = TUMOR_NORMAL.out.vcf
    tumor_only_vcf   = TUMOR_ONLY.out.vcf
    multiqc_report   = REPORTING.out.multiqc_report
}
