process MARKDUPLICATES {
    tag "${meta.id}"
    label 'process_medium'
    container 'broadinstitute/gatk:4.5.0.0'
    publishDir "${params.outdir}/qc/alignment_metrics", mode: 'copy', pattern: "*.metrics.txt"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${meta.id}.markdup.bam"),         emit: bam
    path("${meta.id}.markdup.metrics.txt"),                  emit: metrics
    path("versions.yml"),                                    emit: versions

    script:
    def avail_mem = task.memory ? "-Xmx${task.memory.toGiga()}g" : "-Xmx4g"
    """
    gatk --java-options "${avail_mem}" MarkDuplicates \
        -I ${bam} \
        -O ${meta.id}.markdup.bam \
        -M ${meta.id}.markdup.metrics.txt \
        --VALIDATION_STRINGENCY SILENT

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(gatk --version | grep "The Genome Analysis Toolkit" | sed 's/.*v//')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}.markdup.bam
    echo "# MarkDuplicatesStubMetrics" > ${meta.id}.markdup.metrics.txt
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: 4.5.0.0
    END_VERSIONS
    """
}
