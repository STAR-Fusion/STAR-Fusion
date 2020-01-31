workflow star_fusion_workflow {
    File left_fq
    File right_fq
    String sample_id
    # either a gs:// URL to a tar.gz2 file or an acronym
    String genome

    String? fusion_inspector # inspect or validate
    #   e.g  --no_annotation_filter --min_FFPM 0
    String? additional_flags

    # cpus and memory defaults are read from acronym file by default.
    Int? num_cpu
    String? memory

    String? docker = "trinityctat/starfusion:1.8.1b"

    Float? extra_disk_space = 10
    Float? fastq_disk_space_multiplier = 3.25
    Float? genome_disk_space_multiplier = 2.5

    String? acronym_file = "gs://regev-lab/resources/ctat/star_fusion/index.json"

    Int? preemptible = 2
    Boolean? use_ssd = true
    String config_docker = "continuumio/miniconda3:4.6.14"
    String? zones = "us-central1-a us-central1-b us-central1-c us-central1-f us-east1-b us-east1-c us-east1-d us-west1-a us-west1-b us-west1-c"

    call star_fusion_config {
        input:
            genome=genome,
            acronym_file=acronym_file,
            docker=config_docker,
            cpus=num_cpu,
            memory=memory,
            preemptible = preemptible
    }

    call star_fusion {
        input:
            left_fq=left_fq,
            right_fq=right_fq,
            additional_flags=additional_flags,
            sample_id=sample_id,
            fusion_inspector=fusion_inspector,
            extra_disk_space=extra_disk_space,
            fastq_disk_space_multiplier=fastq_disk_space_multiplier,
            genome_disk_space_multiplier=genome_disk_space_multiplier,
            zones = zones,
            preemptible = preemptible,
            docker = docker,
            genome=star_fusion_config.star_genome,
            cpu=star_fusion_config.star_cpus_output,
            memory=star_fusion_config.star_memory_output,
            use_ssd=use_ssd
    }

    output {
        File fusion_predictions = star_fusion.fusion_predictions
        File fusion_predictions_abridged = star_fusion.fusion_predictions_abridged
        File bam=star_fusion.bam
        File star_log_final=star_fusion.star_log_final
        File junction = star_fusion.junction
        File sj = star_fusion.sj
        Array[File] fusion_inspector_validate_fusions_abridged = star_fusion.fusion_inspector_validate_fusions_abridged
        Array[File] fusion_inspector_validate_web =  star_fusion.fusion_inspector_validate_web
        Array[File] fusion_inspector_inspect_web  =  star_fusion.fusion_inspector_inspect_web
        Array[File] fusion_inspector_inspect_fusions_abridged = star_fusion.fusion_inspector_inspect_fusions_abridged

    }
}



task star_fusion_config {
    String genome
    File acronym_file
    Int? cpus
    String? memory
    String docker
    Int preemptible

    command {
        set -e

        python <<CODE

        import json
        genome = '${genome}'
        acronym_file = '${acronym_file}'
        cpu = '${cpus}'
        memory = '${memory}'
        genome_lc = genome.lower()
        is_url = genome_lc.startswith('gs://')

        if not is_url:
            with open(acronym_file, 'r') as f:
                config = json.load(f)
            if genome_lc in config:
                config = config[genome_lc]
                genome = config['url']
                if cpu == '':
                    cpu = config.get('cpus', '12')
                if memory == '':
                    memory = config.get('memory', '42G')
        if cpu == '':
            cpu = '12'
        if memory == '':
            memory = '42G'

        with open('cpu.txt', 'wt') as w1, open('memory.txt', 'wt') as w2, open('genome.txt', 'wt') as w3:
            w1.write(str(cpu))
            w2.write(memory)
            w3.write(genome)
        CODE
    }

    output {
        String star_genome = read_string('genome.txt')
        Int star_cpus_output = read_int('cpu.txt')
        String star_memory_output = read_string('memory.txt')

    }

    runtime {
        cpu:1
        bootDiskSizeGb: 12
        disks: "local-disk 1 HDD"
        memory:"1GB"
        docker: "${docker}"
        preemptible: "${preemptible}"
    }
}

task star_fusion {
    File left_fq
    File right_fq
    File genome
    String sample_id

    String zones
    Int preemptible
    String docker
    Int cpu
    String memory
    Float extra_disk_space
    Float fastq_disk_space_multiplier
    Float genome_disk_space_multiplier
    String? fusion_inspector
    String? additional_flags
    Boolean use_ssd

    command {
        set -e

      #  /software/monitor_script.sh > monitoring.log &

        mkdir -p ${sample_id}
        mkdir -p genome_dir

        pbzip2 -dc ${genome} | tar x -C genome_dir --strip-components 1

        /usr/local/src/STAR-Fusion/STAR-Fusion \
        --genome_lib_dir `pwd`/genome_dir/ctat_genome_lib_build_dir \
        --left_fq ${left_fq} \
        --right_fq ${right_fq} \
        --output_dir ${sample_id} \
        --CPU ${cpu} \
        ${"--FusionInspector " + fusion_inspector} \
        ${" " + additional_flags}
    }

    output {
#        File monitoringLog = "monitoring.log"
        File fusion_predictions = "${sample_id}/star-fusion.fusion_predictions.tsv"
        File fusion_predictions_abridged = "${sample_id}/star-fusion.fusion_predictions.abridged.tsv"
        File bam="${sample_id}/Aligned.out.bam"
        File star_log_final="${sample_id}/Log.final.out"
        File junction = "${sample_id}/Chimeric.out.junction"
        File sj = "${sample_id}/SJ.out.tab"
        Array[File] fusion_inspector_validate_fusions_abridged = glob("${sample_id}/FusionInspector-validate/finspector.FusionInspector.fusions.abridged.tsv")
        Array[File] fusion_inspector_validate_web = glob("${sample_id}/FusionInspector-validate/finspector.fusion_inspector_web.html")
        Array[File] fusion_inspector_inspect_web  = glob("${sample_id}/FusionInspector-inspect/finspector.fusion_inspector_web.html")
        Array[File] fusion_inspector_inspect_fusions_abridged = glob("${sample_id}/FusionInspector-inspect/finspector.FusionInspector.fusions.abridged.tsv")
    }

    runtime {
        docker: "${docker}"
        zones: zones
        disks: "local-disk " + ceil((fastq_disk_space_multiplier * (size(left_fq,  "GB") + size(right_fq,  "GB"))) +size(genome, "GB")*genome_disk_space_multiplier + extra_disk_space)+ " " + (if use_ssd then "SSD" else "HDD")
        memory :"${memory}"
        preemptible: "${preemptible}"
        cpu:"${cpu}"
    }
}
