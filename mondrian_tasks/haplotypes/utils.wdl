version 1.0

task ExtractSeqDataAndReadCount{
    input{
        File bam
        File? bai
        File snp_positions
        File segments
        File haplotypes
        Array[String] chromosomes
        Boolean? skip_header = false
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        if [[ -z "~{bai}" ]]; then
            samtools index ~{bam}
        fi

        cellid=$(basename ~{bam})
        cellid="${cellid%.*}"

        mkdir -p readcount_temp seqdata_temp

        haplotype_utils extract_seqdata --bam ~{bam} \
        --snp_positions ~{snp_positions} \
        --output seqdata_temp/output.h5 \
        --tempdir seqdata_temp \
        --chromosomes ~{sep=" "chromosomes} \
        --cell_id $cellid

        haplotype_utils haplotype_allele_readcount \
        --seqdata seqdata_temp/output.h5 \
        --segments ~{segments} \
        --haplotypes ~{haplotypes} \
        --output allele_counts.csv.gz \
        --tempdir readcount_temp \
        ~{true='--skip_header' false='' skip_header} \
    >>>
    output{
        File outfile = "allele_counts.csv.gz"
        File outfile_yaml = "allele_counts.csv.gz.yaml"
    }
    runtime{
        memory: "~{select_first([memory_override, 14])} GB"
        walltime: "~{select_first([walltime_override, 6])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}


task GetAlleleCounts{
    input{
        File bam
        File bai
        File snp_positions
        Boolean skip_header = false
        String region
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        haplotype_utils get_allele_counts --bam ~{bam} \
        --snp_positions ~{snp_positions} \
        --output counts.csv.gz \
        --region ~{region} \
        ~{true='--skip_header' false='' skip_header} \
    >>>
    output{
        File counts_csv = "counts.csv.gz"
        File counts_yaml = "counts.csv.gz.yaml"
    }
    runtime{
        memory: "~{select_first([memory_override, 24])} GB"
        walltime: "~{select_first([walltime_override, 72])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}


task InferSnpGenotype{
    input{
        File allele_counts
        File allele_counts_yaml
        String chromosome
        String data_type = 'normal'
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
    haplotype_utils infer_snp_genotype \
    --allele_counts ~{allele_counts} \
    --output snp_genotype.csv.gz \
    --chromosome  ~{chromosome} \
    --data_type ~{data_type}
    >>>
    output{
        File snp_genotype = "snp_genotype.csv.gz"
        File snp_genotype_yaml = "snp_genotype.csv.gz.yaml"
    }
    runtime{
        memory: "~{select_first([memory_override, 7])} GB"
        walltime: "~{select_first([walltime_override, 6])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}



task InferHaps{
    input{
        File snp_genotype
        File snp_genotype_yaml
        File thousand_genomes_tar
        File snp_positions
        String chromosome
        String? sex = 'female'
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        haplotype_utils infer_haps \
        --snp_genotype ~{snp_genotype} \
        --thousand_genomes_tar ~{thousand_genomes_tar} \
        --output haplotypes.tsv \
        --chromosome ~{chromosome} \
        --tempdir tempdir \
        --snp_positions ~{snp_positions} \
        --sex ~{sex}
    >>>
    output{
        File haplotypes = "haplotypes.tsv"
    }
    runtime{
        memory: "~{select_first([memory_override, 24])} GB"
        walltime: "~{select_first([walltime_override, 24])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}


task MergeSeqData{
    input{
        Array[File] infiles
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        haplotype_utils merge_seqdata --inputs ~{sep=" "infiles} --output output.h5
    >>>
    output{
        File merged_haps = "output.h5"
    }
    runtime{
        memory: "~{select_first([memory_override, 7])} GB"
        walltime: "~{select_first([walltime_override, 6])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}



task MergeHaps{
    input{
        Array[File] infiles
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        haplotype_utils merge_haps --inputs ~{sep=" "infiles} --output output.tsv
    >>>
    output{
        File merged_haps = "output.tsv"
    }
    runtime{
        memory: "~{select_first([memory_override, 7])} GB"
        walltime: "~{select_first([walltime_override, 6])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}


task AnnotateHaps{
    input{
        File infile
        File thousand_genomes_snps
        String? filename_prefix = "annotate_haps"
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        haplotype_utils annotate_haps --input ~{infile} \
        --thousand_genomes ~{thousand_genomes_snps} \
        --output ~{filename_prefix}.csv.gz --tempdir tmpdir
    >>>
    output{
        File outfile = "~{filename_prefix}.csv.gz"
        File outfile_yaml = "~{filename_prefix}.csv.gz.yaml"
    }
    runtime{
        memory: "~{select_first([memory_override, 24])} GB"
        walltime: "~{select_first([walltime_override, 6])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}



task CreateSegments{
    input{
        File reference_fai
        File gap_table
        Array[String] chromosomes
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        haplotype_utils create_segments \
        --reference_fai ~{reference_fai} \
        --gap_table ~{gap_table} \
        --chromosomes ~{sep=" "chromosomes} \
        --output output.tsv --tempdir temp
    >>>
    output{
        File segments = "output.tsv"
    }
    runtime{
        memory: "~{select_first([memory_override, 7])} GB"
        walltime: "~{select_first([walltime_override, 6])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}


task ConvertHaplotypesCsvToTsv{
    input{
        File infile
        File infile_yaml
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        haplotype_utils convert_haplotypes_csv_to_tsv \
        --input ~{infile} \
        --output output.tsv
    >>>
    output{
        File outfile = "output.tsv"
    }
    runtime{
        memory: "~{select_first([memory_override, 7])} GB"
        walltime: "~{select_first([walltime_override, 6])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}




task HaplotypesMetadata{
    input{
        Map[String, Array[File]] files
        Array[File] metadata_yaml_files
        Array[String] samples
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        haplotype_utils generate_metadata \
        --files ~{write_json(files)} \
        --metadata_yaml_files ~{sep=" "metadata_yaml_files} \
        --samples ~{sep=" "samples} \
        --metadata_output metadata.yaml
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





task shapeit4{
    input{
        File bcf_input
        File bcf_idx_input
        File genetic_map
        File regions_file
        File regions_idx_file
        String chromosome
        Array[String] phased_chromosomes
        String phased_chromosome_x
        Boolean? is_female = false
        Int shapeit_num_samples = 100
        Float shapeit_confidence_threshold = 0.95
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        haplotype_utils run_shapeit \
        --input_bcf_file ~{bcf_input} \
        --genetic_map ~{genetic_map} \
        --regions_file ~{regions_file} \
        --chromosome ~{chromosome} \
        --tempdir tempdir \
        --output haplotypes.tsv.gz \
        --phased_chromosomes ~{sep=" " phased_chromosomes} \
        --phased_chromosome_x ~{phased_chromosome_x} \
        --shapeit_num_samples ~{shapeit_num_samples} \
        --shapeit_confidence_threshold ~{shapeit_confidence_threshold} \
        ~{true='--is_female' false='' is_female} \
        --output haplotypes.csv.gz
    >>>
    output{
        File csv_output = "haplotypes.csv.gz"
        File yaml_output = "haplotypes.csv.gz.yaml"
    }
    runtime{
        memory: "~{select_first([memory_override, 7])} GB"
        walltime: "~{select_first([walltime_override, 6])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }

}




