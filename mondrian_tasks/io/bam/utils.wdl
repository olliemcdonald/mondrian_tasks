version 1.0

task SplitBam{
    input{
        File bam
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    command<<<
        bam_utils split_bam_by_barcode --infile ~{bam} --outdir tempdir
    >>>
    output{
        Array[File] cell_bams = glob('tempdir/*bam')
    }
    runtime{
        memory: "~{select_first([memory_override, 30])} GB"
        walltime: "~{select_first([walltime_override, 96])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}



