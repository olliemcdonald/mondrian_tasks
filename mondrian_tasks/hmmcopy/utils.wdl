version 1.0


task RunReadCounter{
    input{
        File bamfile
        File baifile
        File repeats_satellite_regions
        Array[String] chromosomes
        Int num_threads=16
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        hmmcopy_utils readcounter --infile ~{bamfile} --outdir output -w 500000 --chromosomes ~{sep=" --chromosomes "chromosomes} \
        -m 20 --exclude_list ~{repeats_satellite_regions} --tempdir all_cells_temp --ncores ~{num_threads}
    >>>
    output{
        Array[File] wigs = glob('output*/*.wig')
    }
    runtime{
        memory: "~{select_first([memory_override, 10])} GB"
        walltime: "~{select_first([walltime_override, 24])}:00"
        cpu: "~{num_threads}"
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}


task CellCycleClassifier{
    input{
        File hmmcopy_reads
        File hmmcopy_reads_yaml
        File hmmcopy_metrics
        File hmmcopy_metrics_yaml
        File alignment_metrics
        File alignment_metrics_yaml
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
    hmmcopy_utils cell-cycle-classifier --reads ~{hmmcopy_reads} --alignment_metrics ~{alignment_metrics} \
      --hmmcopy_metrics ~{hmmcopy_metrics} --output output.csv.gz --tempdir temp
    >>>
    output{
        File outfile = 'output.csv.gz'
        File outfile_yaml = 'output.csv.gz.yaml'
    }
    runtime{
        memory: "~{select_first([memory_override, 7])} GB"
        walltime: "~{select_first([walltime_override, 6])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }

}

task CellHmmcopy{
    input{
        File bamfile
        File baifile
        File gc_wig
        File map_wig
        File reference
        File reference_fai
        File alignment_metrics
        File alignment_metrics_yaml
        File repeats_satellite_regions
        Array[String] chromosomes
        File quality_classifier_training_data
        File? quality_classifier_model
        String map_cutoff
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    String model_str = if defined(quality_classifier_model) then '--quality_classifier_model ~{quality_classifier_model}' else ''
    command<<<
        hmmcopy_utils run-cell-hmmcopy \
        --bam_file ~{bamfile} \
        --gc_wig_file ~{gc_wig} \
        --map_wig_file ~{map_wig} \
        --alignment_metrics ~{alignment_metrics} \
        --chromosomes ~{sep=" --chromosomes "chromosomes} \
        --metrics metrics.csv.gz \
        --params params.csv.gz \
        --reads reads.csv.gz \
        --segments segments.csv.gz \
        --output_tarball hmmcopy_data.tar.gz \
        --exclude_list ~{repeats_satellite_regions} \
        --reference ~{reference} \
        --segments_output segments.pdf \
        --bias_output bias.pdf \
        --tempdir output \
        --map_cutoff ~{map_cutoff} \
        --quality_classifier_training_data ~{quality_classifier_training_data} \
        ~{model_str}
    >>>
    output{
        File reads = 'reads.csv.gz'
        File reads_yaml = 'reads.csv.gz.yaml'
        File params = 'params.csv.gz'
        File params_yaml = 'params.csv.gz.yaml'
        File segments = 'segments.csv.gz'
        File segments_yaml = 'segments.csv.gz.yaml'
        File metrics = 'metrics.csv.gz'
        File metrics_yaml = 'metrics.csv.gz.yaml'
        File tarball = 'hmmcopy_data.tar.gz'
        File segments_pdf = 'segments.pdf'
        File segments_sample = 'segments.pdf.sample'
        File bias_pdf = 'bias.pdf'
    }
    runtime{
        memory: "~{select_first([memory_override, 47])} GB"
        walltime: "~{select_first([walltime_override, 6])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}



task Hmmcopy{
    input{
        File readcount_wig
        File gc_wig
        File map_wig
        File reference
        File reference_fai
        File alignment_metrics
        File alignment_metrics_yaml
        File quality_classifier_training_data
        File? quality_classifier_model
        String map_cutoff
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    String model_str = if defined(quality_classifier_model) then '--quality_classifier_model ~{quality_classifier_model}' else ''
    command<<<
        hmmcopy_utils run-hmmcopy \
        --readcount_wig ~{readcount_wig} \
        --gc_wig_file ~{gc_wig} \
        --map_wig_file ~{map_wig} \
        --alignment_metrics ~{alignment_metrics} \
        --metrics metrics.csv.gz \
        --params params.csv.gz \
        --reads reads.csv.gz \
        --segments segments.csv.gz \
        --output_tarball hmmcopy_data.tar.gz \
        --reference ~{reference} \
        --segments_output segments.pdf \
        --bias_output bias.pdf \
        --cell_id $(basename ~{readcount_wig} .wig) \
        --tempdir output \
        --map_cutoff ~{map_cutoff} \
        --quality_classifier_training_data ~{quality_classifier_training_data} \
        ~{model_str}
    >>>
    output{
        File reads = 'reads.csv.gz'
        File reads_yaml = 'reads.csv.gz.yaml'
        File params = 'params.csv.gz'
        File params_yaml = 'params.csv.gz.yaml'
        File segments = 'segments.csv.gz'
        File segments_yaml = 'segments.csv.gz.yaml'
        File metrics = 'metrics.csv.gz'
        File metrics_yaml = 'metrics.csv.gz.yaml'
        File tarball = 'hmmcopy_data.tar.gz'
        File segments_pdf = 'segments.pdf'
        File segments_sample = 'segments.pdf.sample'
        File bias_pdf = 'bias.pdf'
    }
    runtime{
        memory: "~{select_first([memory_override, 7])} GB"
        walltime: "~{select_first([walltime_override, 6])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}

task PlotHeatmap{
    input{
        File reads
        File reads_yaml
        File metrics
        File metrics_yaml
        Array[String] chromosomes
        Boolean disable_clustering=false
        String? sidebar_column='pick_met'
        String? filename_prefix = "heatmap"
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        hmmcopy_utils heatmap --reads ~{reads} --metrics ~{metrics} \
        --output ~{filename_prefix}.pdf --chromosomes ~{sep=" --chromosomes "chromosomes} \
        --sidebar_column ~{sidebar_column} \
        ~{true='--disable_clustering' false='' disable_clustering}
     >>>
    output{
        File heatmap_pdf = '~{filename_prefix}.pdf'
    }
    runtime{
        memory: "~{select_first([memory_override, 7])} GB"
        walltime: "~{select_first([walltime_override, 6])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}




task CreateSegmentsTar{
    input{
        File hmmcopy_metrics
        File hmmcopy_metrics_yaml
        Array[File] segments_plot
        Array[File] segments_plot_sample
        String? filename_prefix = "segments_pdf_tar"
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override

    }
    command<<<
    hmmcopy_utils create-segs-tar --segs_pdf ~{sep = " --segs_pdf " segments_plot} \
    --metrics ~{hmmcopy_metrics} --pass_output ~{filename_prefix}_pass.tar.gz \
    --fail_output ~{filename_prefix}_fail.tar.gz --tempdir temp
    >>>
    output{
        File segments_pass = "~{filename_prefix}_pass.tar.gz"
        File segments_fail = "~{filename_prefix}_fail.tar.gz"
    }
    runtime{
        memory: "~{select_first([memory_override, 7])} GB"
        walltime: "~{select_first([walltime_override, 6])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}



task GenerateHtmlReport{
    input{
        File metrics
        File metrics_yaml
        File gc_metrics
        File gc_metrics_yaml
        String? filename_prefix = "html_report"
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
    hmmcopy_utils generate-html-report \
     --tempdir temp --html ~{filename_prefix}_report.html \
     --metrics ~{metrics} \
     --gc_metrics ~{gc_metrics}
    >>>
    output{
        File html_report = "~{filename_prefix}_report.html"
    }
    runtime{
        memory: "~{select_first([memory_override, 7])} GB"
        walltime: "~{select_first([walltime_override, 6])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}


task AddClusteringOrder{
    input{
        File metrics
        File metrics_yaml
        File reads
        File reads_yaml
        Array[String] chromosomes
        String? filename_prefix = "added_clustering_order"
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
    hmmcopy_utils add-clustering-order \
     --reads ~{reads} --output ~{filename_prefix}.csv.gz \
     --metrics ~{metrics} --chromosomes ~{sep=" --chromosomes "chromosomes}
    >>>
    output{
        File output_csv = "~{filename_prefix}.csv.gz"
        File output_yaml = "~{filename_prefix}.csv.gz.yaml"
    }
    runtime{
        memory: "~{select_first([memory_override, 7])} GB"
        walltime: "~{select_first([walltime_override, 6])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}


task HmmcopyMetadata{
    input{
        File params
        File params_yaml
        File segments
        File segments_yaml
        File metrics
        File metrics_yaml
        File reads
        File reads_yaml
        File heatmap
        File segments_pass
        File segments_fail
        File metadata_input
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        hmmcopy_utils generate-metadata \
        --params ~{params} ~{params_yaml} \
        --segments ~{segments} ~{segments_yaml} \
        --metrics ~{metrics} ~{metrics_yaml} \
        --reads ~{reads} ~{reads_yaml} \
        --segments_tar_pass ~{segments_pass} \
        --segments_tar_fail ~{segments_fail} \
        --heatmap ~{heatmap} \
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

