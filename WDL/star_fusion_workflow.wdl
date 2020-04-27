version 1.0
import "https://api.firecloud.org/ga4gh/v1/tools/CTAT:star_fusion_tasks/versions/2/plain-WDL/descriptor" as star_fusion_tasks


workflow star_fusion_workflow {
  input {
    String? additional_flags
    Boolean use_ssd = true
    String config_docker = "continuumio/miniconda3:4.6.14"
    String? fusion_inspector
    Int preemptible = 2
    String zones = "us-central1-a us-central1-b us-central1-c us-central1-f us-east1-b us-east1-c us-east1-d us-west1-a us-west1-b us-west1-c"
    Float extra_disk_space = 10
    String sample_id
    Float genome_disk_space_multiplier = 2.5
    File? left_fq
    String docker = "trinityctat/starfusion:1.8.1b"
    File? chimeric_out_junction
    Int? num_cpu
    File? right_fq
    String acronym_file = "gs://regev-lab/resources/ctat/star_fusion/index.json"
    Float fastq_disk_space_multiplier = 3.25
    String genome
    String? memory
  }
  if (defined(chimeric_out_junction)) {
    call star_fusion_kickstart {
      input:
        chimeric_out_junction = chimeric_out_junction,
        genome = star_fusion_config.star_genome,
        sample_id = sample_id,
        zones = zones,
        preemptible = preemptible,
        docker = docker,
        cpu = star_fusion_config.star_cpus_output,
        memory = star_fusion_config.star_memory_output,
        extra_disk_space = extra_disk_space,
        fastq_disk_space_multiplier = fastq_disk_space_multiplier,
        genome_disk_space_multiplier = genome_disk_space_multiplier,
        additional_flags = additional_flags,
        use_ssd = use_ssd
    }
  }
  if (!defined(chimeric_out_junction)) {
    call star_fusion {
      input:
        left_fq = left_fq,
        right_fq = right_fq,
        genome = star_fusion_config.star_genome,
        sample_id = sample_id,
        zones = zones,
        preemptible = preemptible,
        docker = docker,
        cpu = star_fusion_config.star_cpus_output,
        memory = star_fusion_config.star_memory_output,
        extra_disk_space = extra_disk_space,
        fastq_disk_space_multiplier = fastq_disk_space_multiplier,
        genome_disk_space_multiplier = genome_disk_space_multiplier,
        fusion_inspector = fusion_inspector,
        additional_flags = additional_flags,
        use_ssd = use_ssd
    }
  }
  call star_fusion_tasks.star_fusion_config as star_fusion_config {
    input:
      genome = genome,
      acronym_file = acronym_file,
      cpus = num_cpu,
      memory = memory,
      docker = config_docker,
      preemptible = preemptible
  }

  output {
    Array[File]? fusion_inspector_inspect_web = star_fusion.fusion_inspector_inspect_web
    Array[File]? extract_fusion_reads = star_fusion.extract_fusion_reads
    File? fusion_predictions_kickstart = star_fusion_kickstart.fusion_predictions
    Array[File]? fusion_inspector_inspect_fusions_abridged = star_fusion.fusion_inspector_inspect_fusions_abridged
    File? sj = star_fusion.sj
    File? bam = star_fusion.bam
    Array[File]? fusion_inspector_validate_fusions_abridged = star_fusion.fusion_inspector_validate_fusions_abridged
    File? star_log_final = star_fusion.star_log_final
    File? junction = star_fusion.junction
    File? fusion_predictions = star_fusion.fusion_predictions
    Array[File]? fusion_inspector_validate_web = star_fusion.fusion_inspector_validate_web
    File? fusion_predictions_abridged = star_fusion.fusion_predictions_abridged
    File? fusion_predictions_abridged_kickstart = star_fusion_kickstart.fusion_predictions_abridged
  }
}
task star_fusion_kickstart {
  input {
    File? chimeric_out_junction
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
    String? additional_flags
    Boolean use_ssd
  }


  output {
    File fusion_predictions = "${sample_id}/star-fusion.fusion_predictions.tsv"
    File fusion_predictions_abridged = "${sample_id}/star-fusion.fusion_predictions.abridged.tsv"
  }
  command <<<

        set -e

        mkdir -p ~{sample_id}
        mkdir -p genome_dir

        pbzip2 -dc ~{genome} | tar x -C genome_dir --strip-components 1

        /usr/local/src/STAR-Fusion/STAR-Fusion \
        --genome_lib_dir `pwd`/genome_dir/ctat_genome_lib_build_dir \
        -J ~{chimeric_out_junction} \
        --output_dir ~{sample_id} \
        --CPU ~{cpu} \
        ~{"" + additional_flags}

  >>>
  runtime {
    preemptible: "${preemptible}"
    disks: "local-disk " + ceil((fastq_disk_space_multiplier * (size(chimeric_out_junction, "GB"))) + size(genome, "GB") * genome_disk_space_multiplier + extra_disk_space) + " " + (if use_ssd then "SSD" else "HDD")
    docker: "${docker}"
    cpu: "${cpu}"
    zones: zones
    memory: "${memory}"
  }

}
task star_fusion {
  input {
    File? left_fq
    File? right_fq
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
  }


  output {
    Array[File] extract_fusion_reads = glob("${sample_id}/star-fusion.fusion_evidence_*.fq")
    File fusion_predictions = "${sample_id}/star-fusion.fusion_predictions.tsv"
    File fusion_predictions_abridged = "${sample_id}/star-fusion.fusion_predictions.abridged.tsv"
    File bam = "${sample_id}/Aligned.out.bam"
    File star_log_final = "${sample_id}/Log.final.out"
    File junction = "${sample_id}/Chimeric.out.junction"
    File sj = "${sample_id}/SJ.out.tab"
    Array[File] fusion_inspector_validate_fusions_abridged = glob("${sample_id}/FusionInspector-validate/finspector.FusionInspector.fusions.abridged.tsv")
    Array[File] fusion_inspector_validate_web = glob("${sample_id}/FusionInspector-validate/finspector.fusion_inspector_web.html")
    Array[File] fusion_inspector_inspect_web = glob("${sample_id}/FusionInspector-inspect/finspector.fusion_inspector_web.html")
    Array[File] fusion_inspector_inspect_fusions_abridged = glob("${sample_id}/FusionInspector-inspect/finspector.FusionInspector.fusions.abridged.tsv")
  }
  command <<<

        set -e

        mkdir -p ~{sample_id}
        mkdir -p genome_dir

        pbzip2 -dc ~{genome} | tar x -C genome_dir --strip-components 1

        /usr/local/src/STAR-Fusion/STAR-Fusion \
        --genome_lib_dir `pwd`/genome_dir/ctat_genome_lib_build_dir \
        --left_fq ~{left_fq} \
        ~{"--right_fq " + right_fq} \
        --output_dir ~{sample_id} \
        --CPU ~{cpu} \
      ~{"--FusionInspector " + fusion_inspector} \
        ~{"" + additional_flags}


  >>>
  runtime {
    preemptible: "${preemptible}"
    disks: "local-disk " + ceil((fastq_disk_space_multiplier * (size(left_fq, "GB") + size(right_fq, "GB"))) + size(genome, "GB") * genome_disk_space_multiplier + extra_disk_space) + " " + (if use_ssd then "SSD" else "HDD")
    docker: "${docker}"
    cpu: "${cpu}"
    zones: zones
    memory: "${memory}"
  }

}

