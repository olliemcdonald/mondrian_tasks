version 1.0

task BreakpointMetadata{
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

        meta="~{sep=' --metadata_yaml_files 'metadata_yaml_files}"
        if [ ${meta} ]; then
            meta="--metadata_yaml_files ${meta}"
        fi

        samps="~{sep=' --samples 'samples}"
        if [ ${samps} ]; then
            samps="--samples ${samps}"
        fi

        breakpoint_utils breakpoint-generate-metadata \
        --files ~{write_json(files)} \
        ${meta} ${samps} \
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