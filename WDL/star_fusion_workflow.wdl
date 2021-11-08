version 1.0


workflow star_fusion_workflow {
  input {
    
    String sample_id

    File genome_plug_n_play_tar_gz
    
    # input data options
    File? left_fq
    File? right_fq
    File? fastq_pair_tar_gz
    

    # STAR-Fusion parameters
    String? fusion_inspector  # inspect or validate
    String? additional_flags
    
    # runtime params
    String docker = "trinityctat/starfusion:latest"
    Int num_cpu = 12
    Float fastq_disk_space_multiplier = 3.25
    String memory = "50G"
    Float genome_disk_space_multiplier = 2.5
    Int preemptible = 2
    Float extra_disk_space = 10
    Boolean use_ssd = true

  }

    
  call star_fusion {
      input:
        left_fq = left_fq,
        right_fq = right_fq,
        fastq_pair_tar_gz = fastq_pair_tar_gz,
        genome = genome_plug_n_play_tar_gz,
        sample_id = sample_id,
        preemptible = preemptible,
        docker = docker,
        cpu = num_cpu,
        memory = memory,
        extra_disk_space = extra_disk_space,
        fastq_disk_space_multiplier = fastq_disk_space_multiplier,
        genome_disk_space_multiplier = genome_disk_space_multiplier,
        fusion_inspector = fusion_inspector,
        additional_flags = additional_flags,
        use_ssd = use_ssd
    
  }

  output {
    File? reads_per_gene = star_fusion.reads_per_gene
    File? coding_effect = star_fusion.coding_effect
    Array[File]? fusion_inspector_inspect_web = star_fusion.fusion_inspector_inspect_web
    Array[File]? extract_fusion_reads = star_fusion.extract_fusion_reads
    Array[File]? fusion_inspector_inspect_fusions_abridged = star_fusion.fusion_inspector_inspect_fusions_abridged
    File? sj = star_fusion.sj
    File? bam = star_fusion.bam
    Array[File]? fusion_inspector_validate_fusions_abridged = star_fusion.fusion_inspector_validate_fusions_abridged
    File? star_log_final = star_fusion.star_log_final
    File? junction = star_fusion.junction
    File? fusion_predictions = star_fusion.fusion_predictions
    Array[File]? fusion_inspector_validate_web = star_fusion.fusion_inspector_validate_web
    File? fusion_predictions_abridged = star_fusion.fusion_predictions_abridged

  }
}


task star_fusion {
  input {
    String sample_id

    File? left_fq
    File? right_fq
    File? fastq_pair_tar_gz

    File genome
    
    String? fusion_inspector
    String? additional_flags
    
    Int preemptible
    String docker
    Int cpu
    String memory
    Float extra_disk_space
    Float fastq_disk_space_multiplier
    Float genome_disk_space_multiplier
    Boolean use_ssd
  }


  command <<<

    set -ex

    mkdir -p ~{sample_id}

    if [[ ! -z "~{fastq_pair_tar_gz}" ]]; then
        # untar the fq pair
        tar xvf ~{fastq_pair_tar_gz}

        left_fq=(*_1.fastq*)
        right_fq=(*_2.fastq*)
    else
        left_fq="~{left_fq}"
        right_fq="~{right_fq}"
    fi


    if [[ -z "${left_fq[0]}" && -z "${right_fq[0]}" ]]; then
        echo "Error, not finding fastq files here"
        ls -ltr
        exit 1
    fi

    left_fqs=$(IFS=, ; echo "${left_fq[*]}")
    
    read_params="--left_fq ${left_fqs}"
    if [[ "${right_fq[0]}" != "" ]]; then
      right_fqs=$(IFS=, ; echo "${right_fq[*]}")   
      read_params="${read_params} --right_fq ${right_fqs}"
    fi
    
    mkdir -p genome_dir

    pbzip2 -dc ~{genome} | tar x -C genome_dir --strip-components 1

    /usr/local/src/STAR-Fusion/STAR-Fusion \
    --genome_lib_dir `pwd`/genome_dir/ctat_genome_lib_build_dir \
    ${read_params} \
    --output_dir ~{sample_id} \
    --CPU ~{cpu} \
    ~{"--FusionInspector " + fusion_inspector} \
    ~{"" + additional_flags}


  >>>

  output {
    File star_log_final = "~{sample_id}/Log.final.out"
    File junction = "~{sample_id}/Chimeric.out.junction"
    File? coding_effect = "~{sample_id}/star-fusion.fusion_predictions.abridged.coding_effect.tsv"
    File fusion_predictions = "~{sample_id}/star-fusion.fusion_predictions.tsv"
    File fusion_predictions_abridged = "~{sample_id}/star-fusion.fusion_predictions.abridged.tsv"
    File bam = "~{sample_id}/Aligned.out.bam"
    File reads_per_gene = "~{sample_id}/ReadsPerGene.out.tab"
    File sj = "~{sample_id}/SJ.out.tab"
    Array[File] extract_fusion_reads = glob("~{sample_id}/star-fusion.fusion_evidence_*.fq")
    Array[File] fusion_inspector_validate_fusions_abridged = glob("~{sample_id}/FusionInspector-validate/finspector.FusionInspector.fusions.abridged.tsv")
    Array[File] fusion_inspector_validate_web = glob("~{sample_id}/FusionInspector-validate/finspector.fusion_inspector_web.html")
    Array[File] fusion_inspector_inspect_web = glob("~{sample_id}/FusionInspector-inspect/finspector.fusion_inspector_web.html")
    Array[File] fusion_inspector_inspect_fusions_abridged = glob("~{sample_id}/FusionInspector-inspect/finspector.FusionInspector.fusions.abridged.tsv")
  }


  runtime {
    preemptible: preemptible
    disks: "local-disk " + ceil((fastq_disk_space_multiplier * (size(left_fq, "GB") + size(right_fq, "GB"))) + size(genome, "GB") * genome_disk_space_multiplier + extra_disk_space) + " " + (if use_ssd then "SSD" else "HDD")
    docker: docker
    cpu: cpu
    memory: memory
  }

}

