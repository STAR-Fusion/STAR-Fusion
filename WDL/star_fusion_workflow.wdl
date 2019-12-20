workflow star_fusion_workflow {
    File left_fq
    File right_fq
    String sample_id
    Int? num_cpu = 64
    String? memory = "57.6G"
    Int? preemptible = 2
    String? docker = "trinityctat/starfusion:1.8.1"
    String genome
    String? zones = "us-central1-a us-central1-b us-central1-c us-central1-f us-east1-b us-east1-c us-east1-d us-west1-a us-west1-b us-west1-c"
    Float? extra_disk_space = 1
    File acronym_file = "gs://regev-lab/resources/ctat/star_fusion/index.tsv"
    Map[String, String] acronym2gsurl = read_map(acronym_file)
    # If reference is a url
    Boolean is_url = sub(genome, "^.+\\.(tgz|gz)$", "URL") == "URL"
    File genome_file = (if is_url then genome else acronym2gsurl[genome])
    String? fusion_inspector # inspect or validate
#   e.g  --no_annotation_filter --min_FFPM 0
    String? additional_flags
     call star_fusion {
            input:
                left_fq=left_fq,
                right_fq=right_fq,
                genome_tar_gz=genome_file,
                additional_flags=additional_flags,
                sample_id=sample_id,
                fusion_inspector=fusion_inspector,
                extra_disk_space=extra_disk_space,
                zones = zones,
                preemptible = preemptible,
                docker = docker,
                cpu=num_cpu,
                memory=memory
    }


    output {
        File fusion_predictions = star_fusion.fusion_predictions
        File fusion_predictions_abridged = star_fusion.fusion_predictions_abridged
        File bam=star_fusion.bam
        File star_log_final=star_fusion.star_log_final
        File junction = star_fusion.junction
        File sj = star_fusion.sj
        Array[File] fusion_inspector_validate_fusions_abridged = star_fusion.fusion_inspector_validate_fusions_abridged
        Array[File] fusion_inspector_validate_web  = star_fusion.fusion_inspector_validate_web
    }
}



task star_fusion {
    File left_fq
    File right_fq
    String sample_id
    File genome_tar_gz
    String zones
    Int preemptible
    String docker
    Int cpu
    String memory
    Float extra_disk_space
    String? fusion_inspector
    String? additional_flags

    command {
        set -e

        mkdir -p genome_dir
        tar xf ${genome_tar_gz} -C genome_dir --strip-components 1
        mkdir ${sample_id}


        /usr/local/src/STAR-Fusion/STAR-Fusion \
        --genome_lib_dir `pwd`/genome_dir/ctat_genome_lib_build_dir \
        --left_fq ${left_fq} \
        --right_fq ${right_fq} \
        --output_dir ${sample_id} \
        --CPU ${cpu} \
        ${"--FusionInspector " + fusion_inspector} \
        ${" " + additional_flags}

        find ${sample_id} -print
    }

    output {
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
        disks: "local-disk " + ceil(size(genome_tar_gz, "GB")*5 + (3.25 * (size(left_fq,  "GB") + size(right_fq,  "GB"))) + extra_disk_space)+ " HDD"
        memory :"${memory}"
        preemptible: "${preemptible}"
        cpu:"${cpu}"
    }
}
