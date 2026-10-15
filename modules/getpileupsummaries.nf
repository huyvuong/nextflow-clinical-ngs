process GETPILEUPSUMMARIES {
    tag "${meta.id}"
    label 'process_low'
    container 'broadinstitute/gatk:4.5.0.0'

    input:
    tuple val(meta), path(bam), path(bai)
    path(germline_resource)

    output:
    tuple val(meta), path("${meta.id}.pileups.table"), emit: table
    path("versions.yml"),                              emit: versions

    script:
    def avail_mem = task.memory ? "-Xmx${task.memory.toGiga()}g" : "-Xmx4g"
    """
    gatk IndexFeatureFile -I ${germline_resource}
    gatk --java-options "${avail_mem}" GetPileupSummaries \
        -I ${bam} \
        -V ${germline_resource} \
        -L ${germline_resource} \
        -O ${meta.id}.pileups.table

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(gatk --version | grep "The Genome Analysis Toolkit" | sed 's/.*v//')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}.pileups.table
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: 4.5.0.0
    END_VERSIONS
    """
}
