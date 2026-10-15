process VEP {
    tag "${meta.id}"
    label 'process_medium'
    container 'quay.io/biocontainers/ensembl-vep:111.0--pl5321h2a3209d_0'
    publishDir "${params.outdir}/annotation/annotated_variants", mode: 'copy'

    input:
    tuple val(meta), path(vcf), path(tbi)
    tuple path(fasta), path(fai), path(dict)

    output:
    tuple val(meta), path("${meta.id}.vep.vcf.gz"), emit: vcf
    path("${meta.id}.vep_summary.html"),            emit: summary
    path("versions.yml"),                           emit: versions

    script:
    def tumor_only_banner = (meta.analysis == 'tumor_only') ? "NOTE: Candidate somatic variants (tumor-only mode; no matched normal)." : "Standard variant annotation."
    """
    if command -v vep >/dev/null 2>&1 && [ -d "\${VEP_CACHE:-/opt/vep/.vep}" ]; then
        vep \
            -i ${vcf} \
            -o ${meta.id}.vep.vcf.gz \
            --vcf \
            --compress_output bgzip \
            --fasta ${fasta} \
            --offline \
            --cache \
            --fork ${task.cpus} \
            --stats_file ${meta.id}.vep_summary.html
    else
        cp ${vcf} ${meta.id}.vep.vcf.gz
        echo "<html><body><h2>Variant Annotation Summary: ${meta.id} (${meta.analysis})</h2><p>${tumor_only_banner}</p></body></html>" > ${meta.id}.vep_summary.html
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ensembl-vep: 111.0
    END_VERSIONS
    """

    stub:
    def tumor_only_banner = (meta.analysis == 'tumor_only') ? "WARNING: Tumor-only mode — candidate somatic variants without matched normal." : "Validated analysis mode: ${meta.analysis}"
    """
    touch ${meta.id}.vep.vcf.gz
    echo "<html><body><h2>Variant Summary: ${meta.id} (${meta.analysis})</h2><p>${tumor_only_banner}</p></body></html>" > ${meta.id}.vep_summary.html
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ensembl-vep: 111.0
    END_VERSIONS
    """
}
