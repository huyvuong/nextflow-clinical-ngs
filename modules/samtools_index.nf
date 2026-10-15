process SAMTOOLS_INDEX {
    tag "${meta.id}"
    label 'process_single'
    container 'quay.io/biocontainers/samtools:1.19.2--h50ea8bc_1'
    publishDir "${params.outdir}/qc/alignment_metrics", mode: 'copy', pattern: "*.flagstat.txt"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path(bam), path("${bam}.bai"), emit: bam_bai
    path("${meta.id}.flagstat.txt"),                emit: flagstat
    path("versions.yml"),                           emit: versions

    script:
    """
    samtools index -@ ${task.cpus} ${bam}
    samtools flagstat ${bam} > ${meta.id}.flagstat.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools --version | head -n 1 | sed 's/samtools //')
    END_VERSIONS
    """

    stub:
    """
    touch ${bam}.bai
    echo "160 + 0 in total (QC-passed reads + QC-failed reads)" > ${meta.id}.flagstat.txt
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: 1.19.2
    END_VERSIONS
    """
}
