/*
 * Runs GATK CalculateContamination and LearnReadOrientationModel (FFPE artifact modeling).
 */
process CALCULATECONTAMINATION {
    tag "${meta.id}"
    label 'process_low'
    container 'broadinstitute/gatk:4.5.0.0'

    input:
    tuple val(meta), path(pileup_table), path(f1r2_tar)

    output:
    tuple val(meta), path("${meta.id}.contamination.table"), path("${meta.id}.read-orientation-model.tar.gz"), emit: contamination
    path("versions.yml"),                                                                                      emit: versions

    script:
    def avail_mem = task.memory ? "-Xmx${task.memory.toGiga()}g" : "-Xmx4g"
    """
    gatk --java-options "${avail_mem}" CalculateContamination \
        -I ${pileup_table} \
        -O ${meta.id}.contamination.table

    gatk --java-options "${avail_mem}" LearnReadOrientationModel \
        -I ${f1r2_tar} \
        -O ${meta.id}.read-orientation-model.tar.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(gatk --version | grep "The Genome Analysis Toolkit" | sed 's/.*v//')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}.contamination.table ${meta.id}.read-orientation-model.tar.gz
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: 4.5.0.0
    END_VERSIONS
    """
}
