version 1.0

workflow star_fusion_tasks {
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

