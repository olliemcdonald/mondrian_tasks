version 1.0

task SplitBam{
    input{
        File bam
        File bai
        Array[String] chromosomes
        Int num_threads=8
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        bam_utils split_bam_by_barcode --infile ~{bam} --outdir outdir --tempdir tempdir --chromosomes ~{sep=" "chromosomes} --ncores ~{num_threads}
    >>>
    output{
        Array[File] cell_bams = glob('outdir/*bam')
    }
    runtime{
        memory: "~{select_first([memory_override, 30])} GB"
        walltime: "~{select_first([walltime_override, 96])}:00"
        cpu: "~{num_threads}"
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}


task OverlappingFractionPerBin{
    input{
        File bamfile
        File baifile
        Array[String] chromosomes
        Int binsize=500000
        Int mapping_quality=20
        Int num_threads=8
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        bam_utils overlapping_fraction_per_bin \
         --bam ~{bamfile} \
         --output reads_with_overlapping_fraction.csv.gz \
         --tempdir tempdir \
         --chromosomes ~{sep=" "chromosomes} \
         --binsize ~{binsize} \
         --mapping_quality ~{mapping_quality} \
         --ncores ~{num_threads} \
    >>>
    output{
        File output_csv = 'reads_with_overlapping_fraction.csv.gz'
        File output_yaml = 'reads_with_overlapping_fraction.csv.gz.yaml'
    }
    runtime{
        memory: "~{select_first([memory_override, 30])} GB"
        walltime: "~{select_first([walltime_override, 96])}:00"
        cpu: "~{num_threads}"
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}

