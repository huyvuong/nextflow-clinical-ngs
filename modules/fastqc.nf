process FASTQC {
    tag "${meta.id}"
    label 'process_low'
    container 'quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0'
    publishDir "${params.outdir}/qc/fastqc", mode: 'copy'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.html"), emit: html
    path("*.zip"),                   emit: zip
    path("versions.yml"),            emit: versions

    script:
    """
    fastqc --threads ${task.cpus} --quiet ${reads}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqc: \$(fastqc --version | sed 's/FastQC v//')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}_R1_fastqc.html ${meta.id}_R2_fastqc.html
    touch ${meta.id}_R1_fastqc.zip ${meta.id}_R2_fastqc.zip
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqc: 0.12.1
    END_VERSIONS
    """
}
