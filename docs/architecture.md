# Pipeline Architecture Enables Unified Multi-Modal Variant Calling

`nextflow-clinical-ngs` implements a modular Nextflow DSL2 architecture modeled on nf-core design principles. All samples pass through a single validated entry point and shared preprocessing subworkflow before branching into specialized variant-calling workflows.

## High-Level Dataflow

```text
                     FASTQ INPUT (samplesheet.csv)
                                  |
                                  v
                     VALIDATE_SAMPLES (Schema & Pairing)
                                  |
                                  v
                        PREPROCESSING (Shared)
                      +------------------------+
                      | FASTQC                 |
                      | FASTP                  |
                      | BWA_MEM2               |
                      | SAMTOOLS_SORT          |
                      | MARKDUPLICATES         |
                      | SAMTOOLS_INDEX         |
                      | BQSR (configurable)    |
                      +------------------------+
                                  |
                                  v
                            ROUTE_SAMPLES
                                  |
             +--------------------+--------------------+
             |                    |                    |
             v                    v                    v
         GERMLINE           TUMOR_NORMAL          TUMOR_ONLY
             |                    |                    |
      HAPLOTYPECALLER          MUTECT2              MUTECT2
        (GVCF mode)          (Matched T/N)       (Unmatched T)
             |                    |                    |
       GENOTYPEGVCFS     GETPILEUPSUMMARIES   GETPILEUPSUMMARIES
    + VariantFiltration  CALCULATECONTAMINATION CALCULATECONTAMINATION
             |             + OrientationBias    + OrientationBias
             |                    |                    |
             |            FILTERMUTECTCALLS    FILTERMUTECTCALLS
             |                    |                    |
             +--------------------+--------------------+
                                  |
                                  v
                              REPORTING
                      +------------------------+
                      | VEP (Annotation)       |
                      | MULTIQC (Aggregated)   |
                      +------------------------+
```

## Module Reuse Design

Rather than duplicating process blocks across somatic workflows, `nextflow-clinical-ngs` parameterizes its DSL2 modules around a consistent metadata map (`meta`):

- **Shared Alignment & Deduplication**: `PREPROCESSING` runs once per sample library (`tuple val(meta), path(reads)`) regardless of downstream analysis mode.
- **Unified Somatic Calling Modules**: `MUTECT2`, `GETPILEUPSUMMARIES`, `CALCULATECONTAMINATION`, and `FILTERMUTECTCALLS` are imported into both `workflows/tumor_normal.nf` and `workflows/tumor_only.nf`. When `normal_bam` is passed as an empty list `[]`, `MUTECT2` automatically omits `-I <normal_bam> -normal <normal_id>` and executes tumor-only calling.
- **Multi-Tumor Patient Disambiguation**: `VALIDATE_SAMPLES` and `ROUTE_SAMPLES` group paired samples by `meta.pair_id` (which defaults to `patient_id` if no explicit `pair_id` column is supplied), preventing accidental cross-pairing when a patient has longitudinal or multi-region tumor biopsies.

## Tumor-Only Interpretation Limitations

Without a matched normal sample, rare germline variants cannot be distinguished from true somatic mutations with certainty even when filtering against a population germline resource (e.g., gnomAD) and a Panel of Normals (PoN). `FILTERMUTECTCALLS` and `VEP` explicitly tag `tumor_only` outputs as candidate somatic calls requiring downstream clinical curation.
