# nextflow-clinical-ngs: Clinical NGS Meta-Pipeline in Nextflow DSL2

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
[![Docker](https://img.shields.io/badge/container-Docker%20%2F%20BioContainers-blue.svg)](https://biocontainers.pro/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A modular, reproducible **Nextflow DSL2** meta-pipeline supporting **Germline**, **Matched Tumor-Normal**, and **Tumor-Only** short-read DNA variant calling. Built following [nf-core](https://nf-co.re/) conventions with reusable DSL2 process modules, strict samplesheet and pairing validation, synthetic demonstration data, and automated `nf-test` suites.

> **Disclaimer**: This repository is a **research and educational bioinformatics implementation** designed for workflow engineering demonstration. It is **not** a clinically validated diagnostic pipeline.

## Key Features

- **Single Meta-Pipeline Entry Point (`main.nf`)**: Run germline (`--analysis germline`), matched somatic (`--analysis tumor_normal`), unmatched somatic (`--analysis tumor_only`), or mixed cohorts (`--analysis all`) from a single unified samplesheet.
- **Zero Duplicated Preprocessing (`workflows/preprocessing.nf`)**: Every sample shares FastQC, fastp adapter trimming, BWA-MEM2 alignment, coordinate sorting, GATK MarkDuplicates, BAM indexing, and optional GATK Base Quality Score Recalibration (`--run_bqsr`).
- **Reusable Somatic Modules**: Both `TUMOR_NORMAL` and `TUMOR_ONLY` reuse the exact same `MUTECT2`, `GETPILEUPSUMMARIES`, `CALCULATECONTAMINATION` (with `LearnReadOrientationModel`), and `FILTERMUTECTCALLS` modules.
- **Built-in Synthetic Dataset (`data/test/`)**: Includes a pre-indexed `chr22_mini` reference (`reference.fa`, `.fai`, `.dict`), paired-end reads for all three analysis modes (`G001`, `TN001_T`, `TN001_N`, `TO001`), and VCF resource files (`known_sites.vcf`, `germline_resource.vcf`, `pon.vcf`).
- **WSL2 Resource-Aware Configuration**: Configured in `conf/base.config` and `conf/local.config` to run comfortably on a 16 GB RAM Windows WSL2 Ubuntu machine.

## Architecture Overview

```text
                     FASTQ INPUT (samplesheet.csv)
                                  |
                                  v
                          VALIDATE_SAMPLES
                                  |
                                  v
                        SHARED PREPROCESSING
              +--------------------------------------+
              | FastQC -> fastp -> BWA-MEM2          |
              | samtools sort/index -> MarkDuplicates|
              | Optional: BaseRecalibrator/ApplyBQSR |
              +--------------------------------------+
                                  |
                                  v
                            ROUTE_SAMPLES
                                  |
          +-----------------------+-----------------------+
          |                       |                       |
          v                       v                       v
      GERMLINE              TUMOR-NORMAL             TUMOR-ONLY
          |                       |                       |
   HaplotypeCaller             Mutect2                 Mutect2
     (GVCF mode)            (Matched T/N)           (Unmatched T)
          |                       |                       |
    GenotypeGVCFs          Contamination &         Contamination &
  VariantFiltration        Orientation Bias        Orientation Bias
          |               FilterMutectCalls       FilterMutectCalls
          +-----------------------+-----------------------+
                                  |
                                  v
                     VARIANT ANNOTATION (VEP)
                                  |
                                  v
                       MULTIQC & PIPELINE INFO
```

## Quick Start

### 1. Instant Workflow & Routing Verification (`-stub-run`)
Test the entire DSL2 meta-pipeline skeleton, sample validation, and channel routing in seconds without downloading large containers:

```bash
nextflow run main.nf -profile test -stub-run
```

### 2. Full Containerized Execution on Bundled Test Data
Run all three analysis branches simultaneously using Docker:

```bash
nextflow run main.nf \
    --input data/test/samplesheet.csv \
    --analysis all \
    --reference data/test/reference/reference.fa \
    --outdir results \
    -profile test,docker,local
```

### 3. Mode-Specific CLI Examples

```bash
# Germline analysis
nextflow run main.nf \
    --input data/test/samplesheet.csv \
    --analysis germline \
    --reference data/test/reference/reference.fa \
    --outdir results/germline \
    -profile docker

# Matched Tumor-Normal somatic analysis
nextflow run main.nf \
    --input data/test/samplesheet.csv \
    --analysis tumor_normal \
    --reference data/test/reference/reference.fa \
    --outdir results/tumor_normal \
    -profile docker

# Tumor-Only candidate somatic analysis
nextflow run main.nf \
    --input data/test/samplesheet.csv \
    --analysis tumor_only \
    --reference data/test/reference/reference.fa \
    --outdir results/tumor_only \
    -profile docker
```

## Output Directory Structure

```text
results/
├── germline/
│   └── G001.filtered.vcf.gz
├── tumor_normal/
│   └── P002.filtered.vcf.gz
├── tumor_only/
│   └── TO001.filtered.vcf.gz
├── annotation/
│   └── annotated_variants/
├── qc/
│   ├── fastqc/
│   ├── fastp/
│   ├── alignment_metrics/
│   └── multiqc_report.html
└── pipeline_info/
    ├── execution_report.html
    ├── timeline.html
    ├── pipeline_dag.svg
    └── software_versions.yml
```

## Repository Structure

```text
nextflow-clinical-ngs/
├── main.nf
├── nextflow.config
├── nf-test.config
├── modules.json
├── README.md
├── LICENSE
├── conf/
│   ├── base.config
│   ├── docker.config
│   ├── local.config
│   └── test.config
├── workflows/
│   ├── clinical_ngs.nf
│   ├── preprocessing.nf
│   ├── germline.nf
│   ├── tumor_normal.nf
│   ├── tumor_only.nf
│   └── reporting.nf
├── modules/
│   ├── fastqc.nf
│   ├── fastp.nf
│   ├── bwa_mem2.nf
│   ├── samtools_sort.nf
│   ├── samtools_index.nf
│   ├── markduplicates.nf
│   ├── bqsr.nf
│   ├── haplotypecaller.nf
│   ├── genotypegvcfs.nf
│   ├── mutect2.nf
│   ├── getpileupsummaries.nf
│   ├── calculatecontamination.nf
│   ├── filtermutectcalls.nf
│   ├── vep.nf
│   └── multiqc.nf
├── assets/
│   └── samplesheet_schema.json
├── data/
│   └── test/
├── tests/
│   ├── germline.nf.test
│   ├── tumor_normal.nf.test
│   └── tumor_only.nf.test
└── docs/
    ├── architecture.md
    ├── installation.md
    └── usage.md
```

## Milestone Tags

| Tag | Milestone | Description |
| :--- | :--- | :--- |
| `v0.1.0` | Milestone 1 | DSL2 workflow skeleton, samplesheet validation, and sample routing |
| `v0.2.0` | Milestone 2 | Shared preprocessing (FastQC, fastp, BWA-MEM2, samtools, MarkDuplicates, configurable BQSR) |
| `v0.3.0` | Milestone 3 | Germline calling (GATK HaplotypeCaller GVCF, GenotypeGVCFs, VariantFiltration) |
| `v0.4.0` | Milestone 4 | Matched Tumor-Normal somatic calling (Mutect2, pileup/contamination, orientation bias, FilterMutectCalls) |
| `v0.5.0` | Milestone 5 | Tumor-Only candidate somatic calling reusing somatic modules with explicit limitation flags |
| `v0.6.0` | Milestone 6 | Variant annotation (Ensembl VEP) and MultiQC aggregation |
| `v0.7.0` | Milestone 7 | Automated positive and negative integration tests with `nf-test` |
| `v0.8.0` | Milestone 8 | Documentation, synthetic dataset, and GitHub portfolio release |
