process MULTIQC {
    label 'process_single'
    container 'quay.io/biocontainers/multiqc:1.21--pyhdfd78af_0'
    publishDir "${params.outdir}/qc", mode: 'copy'

    input:
    path(qc_files)

    output:
    path("multiqc_report.html"), emit: report
    path("versions.yml"),        emit: versions

    script:
    """
    multiqc . --filename multiqc_report.html --title "Clinical NGS Meta-Pipeline QC Report"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$(multiqc --version | sed 's/.*version //')
    END_VERSIONS
    """

    stub:
    """
    echo "<html><body><h1>MultiQC Clinical NGS Report (Stub)</h1></body></html>" > multiqc_report.html
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: 1.21
    END_VERSIONS
    """
}
