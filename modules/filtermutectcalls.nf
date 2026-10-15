process FILTERMUTECTCALLS {
    tag "${meta.id}"
    label 'process_low'
    container 'broadinstitute/gatk:4.5.0.0'
    publishDir path: { "${params.outdir}/${meta.analysis}" }, mode: 'copy', pattern: "*.filtered.vcf.gz*"

    input:
    tuple val(meta), path(unfiltered_vcf), path(unfiltered_tbi), path(mutect_stats), path(contamination_table), path(orientation_model)
    tuple path(fasta), path(fai), path(dict)

    output:
    tuple val(meta), path("${meta.id}.filtered.vcf.gz"), path("${meta.id}.filtered.vcf.gz.tbi"), emit: vcf
    path("${meta.id}.filtering.stats.txt"),                                                      emit: stats
    path("versions.yml"),                                                                        emit: versions

    script:
    def avail_mem = task.memory ? "-Xmx${task.memory.toGiga()}g" : "-Xmx4g"
    def mode_note = (meta.analysis == 'tumor_only') ? "WARNING: Tumor-only mode. Candidate somatic calls require careful germline/artifact review." : "Matched tumor-normal somatic calls."
    """
    gatk --java-options "${avail_mem}" FilterMutectCalls \
        -R ${fasta} \
        -V ${unfiltered_vcf} \
        --stats ${mutect_stats} \
        --contamination-table ${contamination_table} \
        --ob-priors ${orientation_model} \
        --filtering-stats ${meta.id}.filtering.stats.txt \
        -O ${meta.id}.filtered.vcf.gz

    echo "# AnalysisMode: ${meta.analysis} | ${mode_note}" >> ${meta.id}.filtering.stats.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(gatk --version | grep "The Genome Analysis Toolkit" | sed 's/.*v//')
    END_VERSIONS
    """

    stub:
    def mode_note = (meta.analysis == 'tumor_only') ? "WARNING: Tumor-only mode. Candidate somatic calls require careful germline/artifact review." : "Matched tumor-normal somatic calls."
    """
    touch ${meta.id}.filtered.vcf.gz ${meta.id}.filtered.vcf.gz.tbi
    echo "# AnalysisMode: ${meta.analysis} | ${mode_note}" > ${meta.id}.filtering.stats.txt
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: 4.5.0.0
    END_VERSIONS
    """
}
