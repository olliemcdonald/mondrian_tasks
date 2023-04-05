version 1.0

task SplitBam{
    input{
        File bam
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



