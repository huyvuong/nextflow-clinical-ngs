process BWA_MEM2 {
    tag "${meta.id}"
    label 'process_medium'
    container 'quay.io/biocontainers/bwa-mem2:2.2.1--hd03093a_5'

    input:
    tuple val(meta), path(reads)
    tuple path(fasta), path(fai), path(dict)

    output:
    tuple val(meta), path("${meta.id}.aligned.sam"), emit: sam
    path("versions.yml"),                            emit: versions

    script:
    def (r1, r2) = reads
    def rg = "@RG\\tID:${meta.id}\\tSM:${meta.id}\\tPL:ILLUMINA\\tLB:${meta.patient_id}"
    """
    bwa-mem2 index ${fasta}
    bwa-mem2 mem \
        -t ${task.cpus} \
        -R '${rg}' \
        ${fasta} \
        ${r1} ${r2} > ${meta.id}.aligned.sam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bwa-mem2: \$(bwa-mem2 version 2>/dev/null | head -n 1 || echo "2.2.1")
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}.aligned.sam
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bwa-mem2: 2.2.1
    END_VERSIONS
    """
}
