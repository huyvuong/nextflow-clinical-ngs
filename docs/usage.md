# Command-Line Usage Supports Single-Branch and Mixed-Cohort Execution

## Samplesheet Format

Provide a comma-separated file (`samplesheet.csv`) with the following columns:

```csv
sample_id,patient_id,analysis,role,fastq_1,fastq_2
G001,P001,germline,normal,data/test/fastq/g001_R1.fq.gz,data/test/fastq/g001_R2.fq.gz
TN001_T,P002,tumor_normal,tumor,data/test/fastq/tn001_t_R1.fq.gz,data/test/fastq/tn001_t_R2.fq.gz
TN001_N,P002,tumor_normal,normal,data/test/fastq/tn001_n_R1.fq.gz,data/test/fastq/tn001_n_R2.fq.gz
TO001,P003,tumor_only,tumor,data/test/fastq/to001_R1.fq.gz,data/test/fastq/to001_R2.fq.gz
```

If a single patient has multiple tumor biopsies, add an optional `pair_id` column to group each tumor with its corresponding matched normal.

## Quick Verification (Stub Run)

Verify sample validation, channel routing, and DAG execution in seconds without pulling Docker images:

```bash
nextflow run main.nf -profile test -stub-run
```

## Running Individual Analysis Modes

### 1. Germline Variant Calling
```bash
nextflow run main.nf \
    --input data/test/samplesheet.csv \
    --analysis germline \
    --reference data/test/reference/reference.fa \
    --outdir results/germline \
    -profile docker,local
```

### 2. Matched Tumor-Normal Somatic Calling
```bash
nextflow run main.nf \
    --input data/test/samplesheet.csv \
    --analysis tumor_normal \
    --reference data/test/reference/reference.fa \
    --outdir results/tumor_normal \
    -profile docker,local
```

### 3. Tumor-Only Candidate Somatic Calling
```bash
nextflow run main.nf \
    --input data/test/samplesheet.csv \
    --analysis tumor_only \
    --reference data/test/reference/reference.fa \
    --outdir results/tumor_only \
    -profile docker,local
```

### 4. Unified Mixed-Cohort Execution (`--analysis all`)
```bash
nextflow run main.nf \
    --input data/test/samplesheet.csv \
    --analysis all \
    --reference data/test/reference/reference.fa \
    --outdir results \
    -profile docker,local
```

## Enabling Base Quality Score Recalibration (BQSR)

By default, `--run_bqsr` is `false` for small synthetic datasets where empirical recalibration is statistically underpowered. Enable it on full-scale sequencing runs with:

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --analysis all \
    --reference reference.fa \
    --run_bqsr true \
    --known_sites known_sites.vcf.gz \
    -profile docker,local
```

## Running Automated Tests (`nf-test`)

```bash
nf-test test
```
