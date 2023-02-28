version 1.0


task SeparateTumourAndNormalMetadata{
    input{
        String? normal_bam
        String? normal_bai
        String? tumour_bam
        String? tumour_bai
        File heatmap
        File metadata_input
        File normal_cells_yaml
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    String normal_bam_arg = if defined(normal_bam) then "--normal_bam ~{normal_bam} ~{normal_bai}" else ""
    String tumour_bam_arg = if defined(normal_bam) then "--tumour_bam ~{tumour_bam} ~{tumour_bai}" else ""
    command<<<
        metadata_utils separate_tumour_and_normal \
        --metadata_output metadata.yaml \
        --metadata_input ~{metadata_input} \
        --heatmap heatmap \
        --normal_cells_yaml ~{normal_cells_yaml} \
        ~{normal_bam_arg} ~{tumour_bam_arg}
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
