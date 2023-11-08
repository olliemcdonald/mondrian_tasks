version 1.0

task ConcatVcf{
    input{
        Array[File] vcf_files
        Array[File] csi_files
        Array[File] tbi_files
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        bcftools concat -a -O z -o merged.vcf.gz ~{sep=" " vcf_files}
        vcf-sort merged.vcf.gz > merged_sorted.vcf
        bgzip merged_sorted.vcf -c > merged_sorted.vcf.gz
        tabix -f -p vcf merged_sorted.vcf.gz
        bcftools index merged_sorted.vcf.gz
    >>>
    output{
        File merged_vcf = 'merged_sorted.vcf.gz'
        File merged_vcf_csi = 'merged_sorted.vcf.gz.csi'
        File merged_vcf_tbi = 'merged_sorted.vcf.gz.tbi'
    }
    runtime{
        memory: "~{select_first([memory_override, 7])} GB"
        walltime: "~{select_first([walltime_override, 6])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}

task MergeVcf{
    input{
        Array[File] vcf_files
        Array[File] csi_files
        Array[File] tbi_files
        String? filename_prefix = 'merged_sorted'
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        all_vcfs_string=~{sep=" " vcf_files}
        IFS=' ' read -r -a all_vcfs <<< "$all_vcfs_string"

        if [ "${#all_vcfs[@]}" -eq 1 ]; then
            cp -r ${all_vcfs[0]} merged.vcf.gz
        else
            bcftools merge -O z -o merged.vcf.gz ~{sep=" " vcf_files} --force-samples
        fi
        vcf-sort merged.vcf.gz > merged_sorted.vcf
        bgzip merged_sorted.vcf -c > ~{filename_prefix}.vcf.gz
        tabix -f -p vcf ~{filename_prefix}.vcf.gz
        bcftools index ~{filename_prefix}.vcf.gz
    >>>
    output{
        File merged_vcf = '~{filename_prefix}.vcf.gz'
        File merged_vcf_csi = '~{filename_prefix}.vcf.gz.csi'
        File merged_vcf_tbi = '~{filename_prefix}.vcf.gz.tbi'
    }
    runtime{
        memory: "~{select_first([memory_override, 7])} GB"
        walltime: "~{select_first([walltime_override, 6])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}


task FilterVcf{
    input{
        File vcf_file
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        bcftools view -O z -f .,PASS -o filtered.vcf.gz ~{vcf_file}
        tabix -f -p vcf filtered.vcf.gz
        bcftools index filtered.vcf.gz
    >>>
    output{
        File filtered_vcf = 'filtered.vcf.gz'
        File filtered_vcf_csi = 'filtered.vcf.gz.csi'
        File filtered_vcf_tbi = 'filtered.vcf.gz.tbi'
    }
    runtime{
        memory: "~{select_first([memory_override, 7])} GB"
        walltime: "~{select_first([walltime_override, 6])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}


task FinalizeVcf{
    input{
        File vcf_file
        String? filename_prefix = 'finalize_vcf'
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        vcf-sort ~{vcf_file} > vcf_uncompressed.vcf
        bgzip vcf_uncompressed.vcf -c > ~{filename_prefix}.vcf.gz
        tabix -f -p vcf ~{filename_prefix}.vcf.gz
        bcftools index ~{filename_prefix}.vcf.gz
    >>>
    output{
        File vcf = '~{filename_prefix}.vcf.gz'
        File vcf_csi = '~{filename_prefix}.vcf.gz.csi'
        File vcf_tbi = '~{filename_prefix}.vcf.gz.tbi'
    }
    runtime{
        memory: "~{select_first([memory_override, 7])} GB"
        walltime: "~{select_first([walltime_override, 6])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}



task MpileupAndCall{
    input{
        File bam
        File bai
        File reference_fasta
        File reference_fasta_fai
        File regions_vcf
        File regions_vcf_idx
        String? region
        String? filename_prefix = 'finalize_vcf'
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }

    Boolean defined_region = defined(region)
    command<<<

        if [ ~{defined_region} ]; then
            bcftools view -Oz ~{regions_vcf} ~{region} > subset.vcf.gz
        else
            cp ~{regions_vcf} subset.vcf.gz
        fi

        numcalls=`zcat subset.vcf.gz  | grep -v "#" | wc -l`

        if [ $numcalls == 0 ]; then
            gunzip < subset.vcf.gz | head -n -1 > subset.vcf
            echo -e "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t~{bam}" >> subset.vcf
            bgzip subset.vcf -f
            cp subset.vcf.gz chromosome_mpileup.vcf.gz
        else
            bcftools \
            mpileup -Oz \
            -f ~{reference_fasta} \
            --regions-file subset.vcf.gz \
            ~{bam} \
             -o chromosome_mpileup.vcf.gz
        fi

        bcftools call -Oz \
        -c chromosome_mpileup.vcf.gz \
        -o chromosome_calls.vcf.gz

        echo $(basename ~{bam}) >> samples
        bcftools reheader --samples samples chromosome_calls.vcf.gz > chromosome_calls_reheader.vcf.gz
        bcftools index chromosome_calls_reheader.vcf.gz
    >>>
    output{
        File vcf_output = "chromosome_calls_reheader.vcf.gz"
        File vcf_idx_output = "chromosome_calls_reheader.vcf.gz.csi"
    }
    runtime{
        memory: "~{select_first([memory_override, 14])} GB"
        walltime: "~{select_first([walltime_override, 48])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}

task FilterHet{
    input{
        File bcf
        File bcf_csi
        String? filename_prefix = 'hets_only'
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        bcftools filter -O z \
        -o filtered.vcf.gz \
        -i 'GT[0]="het"' \
        ~{bcf}
        bcftools index filtered.vcf.gz
        tabix -f -p vcf filtered.vcf.gz
    >>>
    output{
        File bcf_output = "filtered.vcf.gz"
        File bcf_csi_output = "filtered.vcf.gz.csi"
        File bcf_tbi_output = "filtered.vcf.gz.tbi"
    }
    runtime{
        memory: "~{select_first([memory_override, 7])} GB"
        walltime: "~{select_first([walltime_override, 6])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}

