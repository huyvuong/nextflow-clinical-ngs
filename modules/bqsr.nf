process BQSR {
    tag "${meta.id}"
    label 'process_medium'
    container 'broadinstitute/gatk:4.5.0.0'
    publishDir "${params.outdir}/qc/alignment_metrics", mode: 'copy', pattern: "*.recal.table"

    input:
    tuple val(meta), path(bam), path(bai)
    tuple path(fasta), path(fai), path(dict)
    path(known_sites)

    output:
    tuple val(meta), path("${meta.id}.recal.bam"), emit: bam
    path("${meta.id}.recal.table"),                emit: table
    path("versions.yml"),                          emit: versions

    script:
    def avail_mem = task.memory ? "-Xmx${task.memory.toGiga()}g" : "-Xmx4g"
    """
    gatk IndexFeatureFile -I ${known_sites}
    gatk --java-options "${avail_mem}" BaseRecalibrator \
        -R ${fasta} \
        -I ${bam} \
        --known-sites ${known_sites} \
        -O ${meta.id}.recal.table

    gatk --java-options "${avail_mem}" ApplyBQSR \
        -R ${fasta} \
        -I ${bam} \
        --bqsr-recal-file ${meta.id}.recal.table \
        -O ${meta.id}.recal.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(gatk --version | grep "The Genome Analysis Toolkit" | sed 's/.*v//')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}.recal.bam ${meta.id}.recal.table
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: 4.5.0.0
    END_VERSIONS
    """
}
