process HAPLOTYPECALLER {
    tag "${meta.id}"
    label 'process_medium'
    container 'broadinstitute/gatk:4.5.0.0'

    input:
    tuple val(meta), path(bam), path(bai)
    tuple path(fasta), path(fai), path(dict)

    output:
    tuple val(meta), path("${meta.id}.g.vcf.gz"), path("${meta.id}.g.vcf.gz.tbi"), emit: gvcf
    path("versions.yml"),                                                          emit: versions

    script:
    def avail_mem = task.memory ? "-Xmx${task.memory.toGiga()}g" : "-Xmx4g"
    """
    gatk --java-options "${avail_mem}" HaplotypeCaller \
        -R ${fasta} \
        -I ${bam} \
        -O ${meta.id}.g.vcf.gz \
        -ERC GVCF

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(gatk --version | grep "The Genome Analysis Toolkit" | sed 's/.*v//')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}.g.vcf.gz ${meta.id}.g.vcf.gz.tbi
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: 4.5.0.0
    END_VERSIONS
    """
}
