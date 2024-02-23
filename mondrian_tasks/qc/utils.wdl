version 1.0



task QcMetadata{
    input{
        File bam
        File bai
        File contaminated_bam
        File contaminated_bai
        File control_bam
        File control_bai
        File gc_metrics
        File gc_metrics_yaml
        File metrics
        File metrics_yaml
        File params
        File params_yaml
        File segments
        File segments_yaml
        File reads
        File reads_yaml
        File heatmap
        File qc_report
        File alignment_tarfile
        File hmmcopy_tarfile
        File metadata_input
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        qc_utils generate-metadata \
        --bam ~{bam} ~{bai} \
        --control ~{control_bam} ~{control_bai} \
        --contaminated ~{contaminated_bam} ~{contaminated_bai} \
        --gc_metrics ~{gc_metrics} ~{gc_metrics_yaml} \
        --metrics ~{metrics} ~{metrics_yaml} \
        --params ~{params} ~{params_yaml} \
        --segments ~{segments} ~{segments_yaml} \
        --reads ~{reads} ~{reads_yaml} \
        --heatmap ~{heatmap} \
        --qc_report_html ~{qc_report} \
        --alignment_tar ~{alignment_tarfile} \
        --hmmcopy_tar ~{hmmcopy_tarfile} \
        --metadata_output metadata.yaml \
        --metadata_input ~{metadata_input}
    >>>
    output{
        File metadata_output = "metadata.yaml"
    }
    runtime{
        memory: "~{select_first([memory_override, 7])} GB"
        walltime: "~{select_first([walltime_override, 6])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}
