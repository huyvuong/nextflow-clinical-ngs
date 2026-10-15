/*
 * Reusable Mutect2 module supporting both matched Tumor-Normal and Tumor-Only modes.
 * When normal_bam is empty ([]), runs in Tumor-Only mode automatically.
 */
process MUTECT2 {
    tag "${meta.id}"
    label 'process_medium'
    container 'broadinstitute/gatk:4.5.0.0'

    input:
    tuple val(meta), path(tumor_bam), path(tumor_bai), path(normal_bam), path(normal_bai)
    tuple path(fasta), path(fai), path(dict)
    path(germline_resource)
    path(pon)

    output:
    tuple val(meta), path("${meta.id}.unfiltered.vcf.gz"), path("${meta.id}.unfiltered.vcf.gz.tbi"), path("${meta.id}.unfiltered.vcf.gz.stats"), emit: vcf
    tuple val(meta), path("${meta.id}.f1r2.tar.gz"),                                                                                             emit: f1r2
    path("versions.yml"),                                                                                                                        emit: versions

    script:
    def avail_mem   = task.memory ? "-Xmx${task.memory.toGiga()}g" : "-Xmx4g"
    def normal_args = normal_bam ? "-I ${normal_bam} -normal ${meta.normal_id}" : ""
    """
    gatk IndexFeatureFile -I ${germline_resource}
    gatk IndexFeatureFile -I ${pon}

    gatk --java-options "${avail_mem}" Mutect2 \
        -R ${fasta} \
        -I ${tumor_bam} \
        ${normal_args} \
        --germline-resource ${germline_resource} \
        --panel-of-normals ${pon} \
        --f1r2-tar-gz ${meta.id}.f1r2.tar.gz \
        -O ${meta.id}.unfiltered.vcf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(gatk --version | grep "The Genome Analysis Toolkit" | sed 's/.*v//')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}.unfiltered.vcf.gz ${meta.id}.unfiltered.vcf.gz.tbi ${meta.id}.unfiltered.vcf.gz.stats
    touch ${meta.id}.f1r2.tar.gz
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: 4.5.0.0
    END_VERSIONS
    """
}
