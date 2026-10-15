process FASTP {
    tag "${meta.id}"
    label 'process_low'
    container 'quay.io/biocontainers/fastp:0.23.4--hadf994f_2'
    publishDir "${params.outdir}/qc/fastp", mode: 'copy', pattern: "*.{json,html}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.trim_R{1,2}.fq.gz"), emit: reads
    path("${meta.id}.fastp.json"),                         emit: json
    path("${meta.id}.fastp.html"),                         emit: html
    path("versions.yml"),                                  emit: versions

    script:
    def (r1, r2) = reads
    """
    fastp \
        --in1 ${r1} \
        --in2 ${r2} \
        --out1 ${meta.id}.trim_R1.fq.gz \
        --out2 ${meta.id}.trim_R2.fq.gz \
        --json ${meta.id}.fastp.json \
        --html ${meta.id}.fastp.html \
        --thread ${task.cpus} \
        --detect_adapter_for_pe

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastp: \$(fastp --version 2>&1 | sed 's/fastp //')
    END_VERSIONS
    """

    stub:
    """
    cp ${reads[0]} ${meta.id}.trim_R1.fq.gz
    cp ${reads[1]} ${meta.id}.trim_R2.fq.gz
    echo '{"summary":{"before_filtering":{"total_reads":160},"after_filtering":{"total_reads":160}}}' > ${meta.id}.fastp.json
    touch ${meta.id}.fastp.html
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastp: 0.23.4
    END_VERSIONS
    """
}
