version 1.0
import "Structs.wdl"

workflow BbCallRST {

    meta { description: "Simple workflow to classify RST type in B. burgdorferi genome assemblies." }
    parameter_meta {
        sample_id: "sample_id for the assembly we're classifying"
        input_fa: "draft assembly.fasta to be classified"
    }
    input {
        String sample_id
        File input_fa
    }
    call CallRST {
        input:
            sample_id = sample_id,
            input_fa = input_fa
    }
    output {
        String RST_type = CallRST.RST_type 
        File RST_amplicon = CallRST.RST_amplicon
        File RST_fragments = CallRST.RST_fragments
    }
}

task CallOspC {
    input {
        String sample_id
        File input_fa
        RuntimeAttr? runtime_attr_override
    }
    parameter_meta {
        sample_id: "sample_id for the assembly we're classifying"
        input_fa: "draft assembly.fasta to be classified"
    }
    Int disk_size = 50 + 10 * ceil(size(input_fa, "GB"))
    command <<<
        rst_caller \
            -i "~{input_fa}" \
            -o "results"
    >>>
    output {
        String RST_type = read_string("results/~{sample_id}_RST_TYPE.txt")
        File RST_amplicon = "results/~{sample_id}_AMPLICON.fna" 
        File RST_fragments = "results/~{sample_id}_FRAGMENT_LENGTHS.txt"
    }
    #########################
    RuntimeAttr default_attr = object {
        cpu_cores:          8,
        mem_gb:             32,
        disk_gb:            disk_size,
        boot_disk_gb:       25,
        preemptible_tries:  0,
        max_retries:        0,
        docker:             "mjfos2r/rst_caller:latest"
    }
    RuntimeAttr runtime_attr = select_first([runtime_attr_override, default_attr])
    runtime {
        cpu:                    select_first([runtime_attr.cpu_cores,         default_attr.cpu_cores])
        memory:                 select_first([runtime_attr.mem_gb,            default_attr.mem_gb]) + " GiB"
        disks: "local-disk " +  select_first([runtime_attr.disk_gb,           default_attr.disk_gb]) + " HDD"
        bootDiskSizeGb:         select_first([runtime_attr.boot_disk_gb,      default_attr.boot_disk_gb])
        preemptible:            select_first([runtime_attr.preemptible_tries, default_attr.preemptible_tries])
        maxRetries:             select_first([runtime_attr.max_retries,       default_attr.max_retries])
        docker:                 select_first([runtime_attr.docker,            default_attr.docker])
    }
}
