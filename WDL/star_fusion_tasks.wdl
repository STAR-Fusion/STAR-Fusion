version 1.0

workflow star_fusion_tasks {
}

struct SplitOutput {
  Array[Array[String]] cell
  Array[Array[String]] read1
  Array[Array[String]] read2
}


task split_sample_sheet {
    input {
        File sample_sheet
        Int cells_per_job
        String docker
        Int preemptible
    }

    command <<<
        set -e

        python <<CODE

        import pandas as pd
        import json

        sample_sheet = "~{sample_sheet}"
        # headers Cell,Read1,Read2
        df = pd.read_csv(sample_sheet, sep=None, engine='python', dtype=str)
        paired = 'Read2' in df
        ncells = len(df)
        step = min(ncells, ~{cells_per_job})
        output_json = dict(cell=[], read1=[], read2=[])
        for i in range(0, ncells, step):
            end = min(ncells, i+step)
            subset = df[i:end]
            output_json['cell'].append(subset['Cell'].values.tolist())
            output_json['read1'].append(subset['Read1'].values.tolist())
            if paired:
                output_json['read2'].append(subset['Read2'].values.tolist())
            else:
                output_json['read2'].append([])
        with open('output.json', 'wt') as f:
            f.write(json.dumps(output_json))
        CODE
    >>>

    output {
        SplitOutput split_output = read_json('output.json')
    }

    runtime {
        cpu:1
        bootDiskSizeGb: 12
        disks: "local-disk 1 HDD"
        memory:"1GB"
        docker: "~{docker}"
        preemptible: "~{preemptible}"
    }
}

task concatentate {
    input {
        Array[File] input_files
        String output_name
        String docker
        Int preemptible
    }

    command <<<
        set -e
        output_name="~{output_name}"
        input_files="~{sep="," input_files}"
        IFS=','
        read -ra files <<< "$input_files"
        nfiles=${#files[@]}
        cat ${files[0]} > $output_name
        for (( i=1; i<${nfiles}; i++ )); do
            tail -n +2 ${files[$i]} | cat >> $output_name
        done
    >>>

    output {
        File output_file = "~{output_name}"
    }

    runtime {
        cpu:1
        bootDiskSizeGb: 12
        disks: "local-disk 1 HDD"
        memory:"1GB"
        docker: "~{docker}"
        preemptible: "~{preemptible}"
    }
}

task star_fusion_config {
  input {
    String genome
    File acronym_file
    Int? cpus
    String? memory
    String docker
    Int preemptible
  }

  output {
    String star_genome = read_string("genome.txt")
    Int star_cpus_output = read_int("cpu.txt")
    String star_memory_output = read_string("memory.txt")
  }

  command <<<

        set -e

        python <<CODE

        import json
        genome = '~{genome}'
        acronym_file = '~{acronym_file}'
        cpu = '~{cpus}'
        memory = '~{memory}'
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
    
  >>>
  runtime {
    preemptible: "${preemptible}"
    bootDiskSizeGb: 12
    disks: "local-disk 1 HDD"
    docker: "${docker}"
    cpu: 1
    memory: "1GB"
  }

}

