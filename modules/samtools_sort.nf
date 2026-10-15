process SAMTOOLS_SORT {
    tag "${meta.id}"
    label 'process_low'
    container 'quay.io/biocontainers/samtools:1.19.2--h50ea8bc_1'

    input:
    tuple val(meta), path(sam)

    output:
    tuple val(meta), path("${meta.id}.sorted.bam"), emit: bam
    path("versions.yml"),                           emit: versions

    script:
    """
    samtools sort -@ ${task.cpus} -o ${meta.id}.sorted.bam ${sam}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools --version | head -n 1 | sed 's/samtools //')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}.sorted.bam
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: 1.19.2
    END_VERSIONS
    """
}
