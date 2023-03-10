version 1.0

task IdentifyNormalCells{
    input{
        File hmmcopy_reads
        File hmmcopy_reads_yaml
        File hmmcopy_metrics
        File hmmcopy_metrics_yaml
        String reference_name
        File blacklist_file
        Float? relative_aneuploidy_threshold = 0.05
        Float? ploidy_threshold = 2.5
        Float? allowed_aneuploidy_score = 0.0
        String? filename_prefix = "separate_normal_and_tumour"
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        normalizer_utils identify_normal_cells \
        --reads_data ~{hmmcopy_reads} \
        --metrics_data ~{hmmcopy_metrics} \
        --output_yaml ~{filename_prefix}_normals.yaml \
        --output_csv ~{filename_prefix}_normals.csv.gz \
        --reference_name ~{reference_name} \
        --blacklist_file ~{blacklist_file} \
        --relative_aneuploidy_threshold ~{relative_aneuploidy_threshold} \
        --ploidy_threshold ~{ploidy_threshold} \
        --allowed_aneuploidy_score ~{allowed_aneuploidy_score}
    >>>
    output{
        File normal_cells_yaml = '~{filename_prefix}_normals.yaml'
        File normal_csv = '~{filename_prefix}_normals.csv.gz'
        File normal_csv_yaml = '~{filename_prefix}_normals.csv.gz.yaml'
    }
    runtime{
        memory: "~{select_first([memory_override, 20])} GB"
        walltime: "~{select_first([walltime_override, 48])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}

task SeparateNormalAndTumourBams{
    input{
        File bam
        File bai
        File normal_cells_yaml
        String? filename_prefix = "separate_normal_and_tumour"
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        normalizer_utils separate_normal_and_tumour_cells \
        --infile ~{bam} \
        --normal_cells_yaml ~{normal_cells_yaml} \
        --normal_output ~{filename_prefix}_normal.bam \
        --tumour_output ~{filename_prefix}_tumour.bam
        samtools index ~{filename_prefix}_normal.bam
        samtools index ~{filename_prefix}_tumour.bam
    >>>
    output{
        File normal_bam = '~{filename_prefix}_normal.bam'
        File normal_bai = '~{filename_prefix}_normal.bam.bai'
        File tumour_bam = '~{filename_prefix}_tumour.bam'
        File tumour_bai = '~{filename_prefix}_tumour.bam.bai'
    }
    runtime{
        memory: "~{select_first([memory_override, 20])} GB"
        walltime: "~{select_first([walltime_override, 48])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}


task NormalHeatmap{
    input{
        File metrics
        File metrics_yaml
        File reads
        File reads_yaml
        String? filename_prefix = "separate_normal_and_tumour"
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        normalizer_utils normal_heatmap \
        --metrics ~{metrics} \
        --reads ~{reads} \
        --output ~{filename_prefix}.pdf
    >>>
    output{
        File output_png = '~{filename_prefix}.pdf'
    }
    runtime{
        memory: "~{select_first([memory_override, 20])} GB"
        walltime: "~{select_first([walltime_override, 6])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}

task AneuploidyHeatmap{
    input{
        File metrics
        File metrics_yaml
        File reads
        File reads_yaml
        String? filename_prefix = "separate_normal_and_tumour"
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        normalizer_utils aneuploidy_heatmap \
        --metrics ~{metrics} \
        --reads ~{reads} \
        --output ~{filename_prefix}.pdf
    >>>
    output{
        File output_png = '~{filename_prefix}.pdf'
    }
    runtime{
        memory: "~{select_first([memory_override, 20])} GB"
        walltime: "~{select_first([walltime_override, 6])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}


task SeparateTumourAndNormalMetadata{
    input{
        String? normal_bam
        String? normal_bai
        String? tumour_bam
        String? tumour_bai
        Array[File] heatmap
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
        normalizer_utils separate_tumour_and_normal_metadata \
        --metadata_output metadata.yaml \
        --metadata_input ~{metadata_input} \
        --heatmap ~{sep=" "heatmap} \
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
