version 1.0


task RunReadCounter{
    input{
        File bamfile
        File baifile
        File control_bamfile
        File control_baifile
        File contaminated_bamfile
        File contaminated_baifile
        File repeats_satellite_regions
        Array[String] chromosomes
        String? singularity_image
        String? docker_image

    }
    command<<<
        hmmcopy_utils readcounter --infile ~{bamfile} --outdir output -w 500000 --chromosomes ~{sep=" "chromosomes} -m 20 --exclude_list ~{repeats_satellite_regions}
        hmmcopy_utils readcounter --infile ~{control_bamfile} --outdir output_control -w 500000 --chromosomes ~{sep=" "chromosomes} -m 20 --exclude_list ~{repeats_satellite_regions}
        hmmcopy_utils readcounter --infile ~{contaminated_bamfile} --outdir output_contaminated -w 500000 --chromosomes ~{sep=" "chromosomes} -m 20 --exclude_list ~{repeats_satellite_regions}
    >>>
    output{
        Array[File] wigs = glob('output*/*.wig')
    }
    runtime{
        memory: "12 GB"
        cpu: 1
        walltime: "96:00"
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}


task CorrectReadCount{
    input{
        File infile
        File gc_wig
        File map_wig
        String map_cutoff
        String? singularity_image
        String? docker_image

    }
    command<<<
        hmmcopy_utils correct_readcount --infile ~{infile} --outfile output.wig \
        --map_cutoff ~{map_cutoff} --gc_wig_file ~{gc_wig} --map_wig_file ~{map_wig} \
        --cell_id $(basename ~{infile} .wig)
    >>>
    output{
        File wig = 'output.wig'
    }
    runtime{
        memory: "12 GB"
        cpu: 1
        walltime: "48:00"
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}


task RunHmmcopy{
    input{
        File corrected_wig
        String? singularity_image
        String? docker_image

    }
    command<<<
    hmmcopy_utils run_hmmcopy \
        --corrected_reads ~{corrected_wig} \
        --tempdir output \
        --reads reads.csv.gz \
        --metrics metrics.csv.gz \
        --params params.csv.gz \
        --segments segments.csv.gz \
        --output_tarball hmmcopy_data.tar.gz
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
    }
    runtime{
        memory: "8 GB"
        cpu: 1
        walltime: "6:00"
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}


task PlotHmmcopy{
    input{
        File segments
        File segments_yaml
        File reads
        File reads_yaml
        File params
        File params_yaml
        File metrics
        File metrics_yaml
        File reference
        File reference_fai
        String? singularity_image
        String? docker_image

    }
    command<<<
        hmmcopy_utils plot_hmmcopy --reads ~{reads} --segments ~{segments} --params ~{params} --metrics ~{metrics} \
        --reference ~{reference} --segments_output segments.pdf --bias_output bias.pdf
     >>>
    output{
        File segments_pdf = 'segments.pdf'
        File segments_sample = 'segments.pdf.sample'
        File bias_pdf = 'bias.pdf'
    }
    runtime{
        memory: "8 GB"
        cpu: 1
        walltime: "6:00"
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
        String filename_prefix = "heatmap"
        String? singularity_image
        String? docker_image

    }
    command<<<
        hmmcopy_utils heatmap --reads ~{reads} --metrics ~{metrics} \
        --output ~{filename_prefix}.pdf --chromosomes ~{sep=" "chromosomes}
     >>>
    output{
        File heatmap_pdf = '~{filename_prefix}.pdf'
    }
    runtime{
        memory: "8 GB"
        cpu: 1
        walltime: "6:00"
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}


task AddMappability{
    input{
        File infile
        File infile_yaml
        String? singularity_image
        String? docker_image

        String filename_prefix
    }
    command<<<
    hmmcopy_utils add_mappability --infile ~{infile} --outfile ~{filename_prefix}.csv.gz
    >>>
    output{
        File outfile = '~{filename_prefix}.csv.gz'
        File outfile_yaml = '~{filename_prefix}.csv.gz.yaml'
    }
    runtime{
        memory: "8 GB"
        cpu: 1
        walltime: "6:00"
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }

}


task CellCycleClassifier{
    input{
        File hmmcopy_reads
        File hmmcopy_metrics
        File alignment_metrics
        String? singularity_image
        String? docker_image

    }
    command<<<
    cell_cycle_classifier train-classify ~{hmmcopy_reads} ~{hmmcopy_metrics} ~{alignment_metrics} output.csv.gz

    echo "is_s_phase: bool" > dtypes.yaml
    echo "is_s_phase_prob: float" >> dtypes.yaml
    echo "cell_id: str" >> dtypes.yaml

    csverve rewrite --in_f output.csv.gz --out_f rewrite.csv.gz --dtypes dtypes.yaml --write_header

    >>>
    output{
        File outfile = 'rewrite.csv.gz'
        File outfile_yaml = 'rewrite.csv.gz.yaml'
    }
    runtime{
        memory: "18 GB"
        cpu: 1
        walltime: "6:00"
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }

}

task AddQuality{
    input{
        File hmmcopy_metrics
        File hmmcopy_metrics_yaml
        File alignment_metrics
        File alignment_metrics_yaml
        File classifier_training_data
        String? singularity_image
        String? docker_image

        String filename_prefix
    }
    command<<<
    hmmcopy_utils add_quality --hmmcopy_metrics ~{hmmcopy_metrics} --alignment_metrics ~{alignment_metrics} --training_data ~{classifier_training_data} --output ~{filename_prefix}.csv.gz --tempdir temp
    >>>
    output{
        File outfile = "~{filename_prefix}.csv.gz"
        File outfile_yaml = "~{filename_prefix}.csv.gz.yaml"
    }
    runtime{
        memory: "8 GB"
        cpu: 1
        walltime: "6:00"
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
        String? singularity_image
        String? docker_image

        String filename_prefix
    }
    command<<<
    hmmcopy_utils create_segs_tar --segs_png ~{sep = " " segments_plot} \
    --metrics ~{hmmcopy_metrics} --pass_output ~{filename_prefix}_pass.tar.gz \
    --fail_output ~{filename_prefix}_fail.tar.gz --tempdir temp
    >>>
    output{
        File segments_pass = "~{filename_prefix}_pass.tar.gz"
        File segments_fail = "~{filename_prefix}_fail.tar.gz"
    }
    runtime{
        memory: "8 GB"
        cpu: 1
        walltime: "6:00"
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
        File reference_gc
        String filename_prefix
        String? singularity_image
        String? docker_image

    }
    command<<<
    hmmcopy_utils generate_html_report \
     --tempdir temp --html ~{filename_prefix}_report.html \
     --reference_gc ~{reference_gc} \
     --metrics ~{metrics} \
     --gc_metrics ~{gc_metrics}
    >>>
    output{
        File html_report = "~{filename_prefix}_report.html"
    }
    runtime{
        memory: "8 GB"
        cpu: 1
        walltime: "6:00"
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
        String filename_prefix = "added_clustering_order"
        String? singularity_image
        String? docker_image

    }
    command<<<
    hmmcopy_utils add_clustering_order \
     --reads ~{reads} --output ~{filename_prefix}.csv.gz \
     --metrics ~{metrics}
    >>>
    output{
        File output_csv = "~{filename_prefix}.csv.gz"
        File output_yaml = "~{filename_prefix}.csv.gz.yaml"
    }
    runtime{
        memory: "8 GB"
        cpu: 1
        walltime: "6:00"
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

    }
    command<<<
        hmmcopy_utils generate_metadata \
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
        memory: "12 GB"
        cpu: 1
        walltime: "48:00"
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}

