version 1.0



task RunDestruct{
    input{
        File normal_bam
        File tumour_bam
        File reference
        File reference_fai
        File reference_gtf
        File reference_fa_1_ebwt
        File reference_fa_2_ebwt
        File reference_fa_3_ebwt
        File reference_fa_4_ebwt
        File reference_fa_rev_1_ebwt
        File reference_fa_rev_2_ebwt
        File dgv
        File repeats_satellite_regions
        String? filename_prefix = "destruct"
        String? singularity_image
        String? docker_image
        Int? num_threads = 8
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        echo "genome_fasta = '~{reference}'; genome_fai = '~{reference_fai}'; gtf_filename = '~{reference_gtf}'" > config.py

        destruct run $(dirname ~{reference}) \
        ~{filename_prefix}_breakpoint_table.csv ~{filename_prefix}_breakpoint_library_table.csv \
        ~{filename_prefix}_breakpoint_read_table.csv \
        --bam_files ~{tumour_bam} ~{normal_bam} \
        --lib_ids tumour normal \
        --tmpdir tempdir --pipelinedir pipelinedir --submit local --config config.py --loglevel DEBUG --maxjobs ~{num_threads}
    >>>
    output{
        File breakpoint_table = "~{filename_prefix}_breakpoint_table.csv"
        File library_table = "~{filename_prefix}_breakpoint_library_table.csv"
        File read_table = "~{filename_prefix}_breakpoint_read_table.csv"
    }
    runtime{
        memory: "~{select_first([memory_override, 7])} GB"
        walltime: "~{select_first([walltime_override, 96])}:00"
        cpu: num_threads
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}



task ExtractSomatic{
    input{
        File destruct_breakpoints
        File destruct_library
        String? filename_prefix = "extract_somatic"
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        destruct extract_somatic \
        ~{destruct_breakpoints} \
        ~{destruct_library} \
        ~{filename_prefix}_destruct_somatic_breakpoints.csv \
        ~{filename_prefix}_destruct_somatic_library.csv \
        --control_ids normal
    >>>
    output{
        File breakpoint_table = "~{filename_prefix}_destruct_somatic_breakpoints.csv"
        File library_table = "~{filename_prefix}_destruct_somatic_library.csv"
    }
    runtime{
        memory: "~{select_first([memory_override, 7])} GB"
        walltime: "~{select_first([walltime_override, 96])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}

task ExtractCounts{
    input{
        File destruct_reads
        File bam
        File bai
        String region
        String? filename_prefix = "destruct_cell_counts"
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    String region_str = if defined(region) then '--region ~{region}' else ''
    command<<<
        breakpoint_utils destruct_extract_cell_counts  \
        --reads ~{destruct_reads} \
        --bam ~{bam} \
        --output ~{filename_prefix}_destruct_cell_counts.csv.gz \
        ~{region_str}
    >>>
    output{
        File output_csv = "~{filename_prefix}_destruct_cell_counts.csv.gz"
        File output_yaml = "~{filename_prefix}_destruct_cell_counts.csv.gz.yaml"
    }
    runtime{
        memory: "~{select_first([memory_override, 7])} GB"
        walltime: "~{select_first([walltime_override, 96])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}

task MergeCounts{
    input{
        Array[File] counts_files
        Array[File] counts_files_yaml
        String? filename_prefix = "destruct_cell_counts"
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        breakpoint_utils destruct_merge_cell_counts  \
        --infiles ~{sep=" "counts_files} \
        --outfile ~{filename_prefix}_destruct_cell_counts_merged.csv.gz \
    >>>
    output{
        File output_csv = "~{filename_prefix}_destruct_cell_counts_merged.csv.gz"
        File output_yaml = "~{filename_prefix}_destruct_cell_counts_merged.csv.gz.yaml"
    }
    runtime{
        memory: "~{select_first([memory_override, 7])} GB"
        walltime: "~{select_first([walltime_override, 96])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}


task DestructCsvToVcf{
    input{
        File destruct_csv
        File reference_fasta
        String sample_id
        String? filename_prefix = "destruct"
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        breakpoint_utils destruct_csv_to_vcf \
        --infile ~{destruct_csv} \
        --reference ~{reference_fasta} \
        --outfile destruct.vcf \
        --sample_id ~{sample_id}

        vcf-sort destruct.vcf > destruct.sorted.vcf
        bgzip destruct.sorted.vcf -c > ~{filename_prefix}.vcf.gz
        tabix -f -p vcf ~{filename_prefix}.vcf.gz
    >>>
    output{
        File outfile = "~{filename_prefix}.vcf.gz"
        File outfile_tbi = "~{filename_prefix}.vcf.gz.tbi"
    }
    runtime{
        memory: "~{select_first([memory_override, 7])} GB"
        walltime: "~{select_first([walltime_override, 96])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}