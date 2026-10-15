process GENOTYPEGVCFS {
    tag "${meta.id}"
    label 'process_medium'
    container 'broadinstitute/gatk:4.5.0.0'
    publishDir "${params.outdir}/germline", mode: 'copy', pattern: "*.filtered.vcf.gz*"

    input:
    tuple val(meta), path(gvcf), path(tbi)
    tuple path(fasta), path(fai), path(dict)

    output:
    tuple val(meta), path("${meta.id}.filtered.vcf.gz"), path("${meta.id}.filtered.vcf.gz.tbi"), emit: vcf
    path("${meta.id}.germline.summary.txt"),                                                     emit: stats
    path("versions.yml"),                                                                        emit: versions

    script:
    def avail_mem = task.memory ? "-Xmx${task.memory.toGiga()}g" : "-Xmx4g"
    """
    gatk --java-options "${avail_mem}" GenotypeGVCFs \
        -R ${fasta} \
        -V ${gvcf} \
        -O ${meta.id}.raw.vcf.gz

    gatk --java-options "${avail_mem}" VariantFiltration \
        -R ${fasta} \
        -V ${meta.id}.raw.vcf.gz \
        -O ${meta.id}.filtered.vcf.gz \
        --filter-name "LowQD" --filter-expression "QD < 2.0" \
        --filter-name "HighFS" --filter-expression "FS > 60.0" \
        --filter-name "LowMQ" --filter-expression "MQ < 40.0"

    echo "Sample: ${meta.id} (Germline mode)" > ${meta.id}.germline.summary.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(gatk --version | grep "The Genome Analysis Toolkit" | sed 's/.*v//')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}.filtered.vcf.gz ${meta.id}.filtered.vcf.gz.tbi
    echo "Sample: ${meta.id} (Germline stub)" > ${meta.id}.germline.summary.txt
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: 4.5.0.0
    END_VERSIONS
    """
}
