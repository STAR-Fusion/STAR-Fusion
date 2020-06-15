version 1.0

import "https://api.firecloud.org/ga4gh/v1/tools/CTAT:star_fusion_tasks/versions/2/plain-WDL/descriptor" as star_fusion_tasks


workflow star_fusion_smartseq2_workflow {
    input {

        String sample_id
        # either a gs:// URL to a tar.gz2 file or an acronym
        String genome

        #   e.g  --no_annotation_filter --min_FFPM 0
        String? additional_flags = "--min_junction_reads 0 --min_FFPM 0 --min_sum_frags 1 --require_LDAS 0 --min_spanning_frags_only 1"

        # cpus and memory defaults are read from acronym file by default.
        Int? num_cpu
        String? memory

        String? docker
        Float extra_disk_space = 30
        Float fastq_disk_space_multiplier = 3.25
        Float genome_disk_space_multiplier = 2.5

        String? acronym_file
        File sample_sheet # csv with Cell,Read1,Read2
        Int? cells_per_job
        Int? preemptible
        String? config_docker
        Boolean? use_ssd
    }

    Int preemptible_or_default = select_first([preemptible, 2])
    Int cells_per_job_or_default = select_first([cells_per_job, 24])
    Boolean use_ssd_or_default = select_first([use_ssd, true])
    String docker_or_default = select_first([docker, "trinityctat/starfusion:1.8.1b"])
    String acronym_file_or_default = select_first([acronym_file, "gs://regev-lab/resources/ctat/star_fusion/index.json"])
    String config_docker_or_default = select_first([config_docker, "continuumio/anaconda3:2020.02"])

    call star_fusion_tasks.star_fusion_config {
        input:
            genome=genome,
            acronym_file=acronym_file_or_default,
            docker=config_docker_or_default,
            cpus=num_cpu,
            memory=memory,
            preemptible = preemptible_or_default
    }

    call star_fusion_tasks.split_sample_sheet {
        input:
            sample_sheet=sample_sheet,
            cells_per_job=cells_per_job_or_default,
            docker=config_docker_or_default,
            preemptible = preemptible_or_default
    }

     scatter(idx in range(length(split_sample_sheet.split_output["read1"]))) {
        call star_fusion {
                input:
                    left_fq=split_sample_sheet.split_output.read1[idx],
                    right_fq=split_sample_sheet.split_output.read2[idx],
                    cell_name=split_sample_sheet.split_output.cell[idx],
                    sample_id=sample_id,
                    additional_flags=additional_flags,
                    extra_disk_space=extra_disk_space,
                    fastq_disk_space_multiplier=fastq_disk_space_multiplier,
                    genome_disk_space_multiplier=genome_disk_space_multiplier,
                    preemptible = preemptible_or_default,
                    docker = docker_or_default,
                    genome=star_fusion_config.star_genome,
                    cpu=star_fusion_config.star_cpus_output,
                    memory=star_fusion_config.star_memory_output,
                    use_ssd=use_ssd_or_default
         }
    }
    call star_fusion_tasks.concatentate as concatentate_fusion_predictions {
        input:
         input_files=star_fusion.fusion_predictions,
         output_name="fusion_predictions.tsv",
         docker=config_docker_or_default,
         preemptible = preemptible_or_default
    }
    call star_fusion_tasks.concatentate as concatentate_fusion_predictions_abridged {
        input:
         input_files=star_fusion.fusion_predictions_abridged,
         output_name="fusion_predictions.abridged.tsv",
         docker=config_docker_or_default,
         preemptible = preemptible_or_default
    }


    call star_fusion_tasks.concatentate as concatentate_fusion_predictions_samples_deconvolved {
        input:
         input_files=star_fusion.fusion_predictions_samples_deconvolved,
         output_name="fusion_predictions_samples_deconvolved.tsv",
         docker=config_docker_or_default,
         preemptible = preemptible_or_default
    }

     call star_fusion_tasks.concatentate as concatentate_fusion_predictions_abridged_samples_deconvolved {
            input:
             input_files=star_fusion.fusion_predictions_abridged_samples_deconvolved,
             output_name="fusion_predictions_abridged_samples_deconvolved.tsv",
             docker=config_docker_or_default,
             preemptible = preemptible_or_default
    }


    output {
        Array[File] bam=star_fusion.bam
        Array[File] star_log_final=star_fusion.star_log_final
        Array[File] junction = star_fusion.junction
        Array[File] sj = star_fusion.sj
        File fusion_predictions = concatentate_fusion_predictions.output_file
        File fusion_predictions_abridged = concatentate_fusion_predictions_abridged.output_file
        File fusion_predictions_samples_deconvolved = concatentate_fusion_predictions_samples_deconvolved.output_file
        File fusion_predictions_abridged_samples_deconvolved = concatentate_fusion_predictions_abridged_samples_deconvolved.output_file

    }
}



task star_fusion {
    input {
        Array[File] left_fq
        Array[File] right_fq
        Array[String] cell_name

        File genome
        String sample_id

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

    command <<<
        set -e

        mkdir -p ~{sample_id}
        mkdir -p genome_dir

        python <<CODE
        left_fq = "~{sep=',' left_fq}".split(',')
        right_fq = "~{sep=',' right_fq}".split(',')
        cell_name = "~{sep=',' cell_name}".split(',')
        with open('samples_file.txt', 'wt') as f:
            for i in range(len(cell_name)):
                f.write(cell_name[i] + '\t')
                f.write(left_fq[i])
                if i < len(right_fq):
                    f.write('\t')
                    f.write(right_fq[i])
                f.write('\n')

        CODE

        pbzip2 -dc ~{genome} | tar x -C genome_dir --strip-components 1

        /usr/local/src/STAR-Fusion/STAR-Fusion \
        --genome_lib_dir `pwd`/genome_dir/ctat_genome_lib_build_dir \
        --samples_file samples_file.txt \
        --output_dir ~{sample_id} \
        --CPU ~{cpu} \
        ~{"" + additional_flags}

    >>>

    output {

        Array[File] extract_fusion_reads = glob("~{sample_id}/star-fusion.fusion_evidence_*.fq")
        File fusion_predictions = "~{sample_id}/star-fusion.fusion_predictions.tsv"
        File fusion_predictions_abridged = "~{sample_id}/star-fusion.fusion_predictions.abridged.tsv"
        File bam="~{sample_id}/Aligned.out.bam"
        File star_log_final="~{sample_id}/Log.final.out"
        File junction = "~{sample_id}/Chimeric.out.junction"
        File sj = "~{sample_id}/SJ.out.tab"
        File fusion_predictions_samples_deconvolved = "~{sample_id}/star-fusion.fusion_predictions.tsv.samples_deconvolved.tsv"
        File fusion_predictions_abridged_samples_deconvolved = "~{sample_id}/star-fusion.fusion_predictions.tsv.samples_deconvolved.abridged.tsv"

    }

    runtime {
        docker: "~{docker}"
        disks: "local-disk " + ceil((fastq_disk_space_multiplier * (size(left_fq,  "GB") + size(right_fq,  "GB"))) +size(genome, "GB")*genome_disk_space_multiplier + extra_disk_space)+ " " + (if use_ssd then "SSD" else "HDD")
        memory :"~{memory}"
        preemptible: "~{preemptible}"
        cpu:"~{cpu}"
    }
}
