version 1.0

task GenerateIntervals{
    input{
        File reference
        Array[String] chromosomes
        Int interval_size = 1000000
        String? singularity_image
        String? docker_image
        Int? memory_override
        Int? walltime_override
    }
    # Changed this command's input to work with an Array and the mondrianutil's cli command that takes multiple options
    command<<<
        variant_utils generate-intervals --reference ~{reference} --chromosomes ~{sep=" --chromosomes " chromosomes} --size ~{interval_size} > intervals.txt
    >>>
    output{
        Array[String] intervals = read_lines('intervals.txt')
    }
    runtime{
        memory: "~{select_first([memory_override, 7])} GB"
        walltime: "~{select_first([walltime_override, 6])}:00"
        cpu: 1
        docker: '~{docker_image}'
        singularity: '~{singularity_image}'
    }
}
