

left_fq="reads_1.fq.gz"
right_fq="reads_2.fq.gz"

check:
ifeq ("", "$(CTAT_GENOME_LIB)")
	echo WARNING: Must specify CTAT_GENOME_LIB env var.
	exit 1
endif

kickstart_hg19:
	../STAR-Fusion --genome_lib_dir ${CTAT_GENOME_LIB}  -J __kickstart_data/hg19.Chimeric.out.junction -O star_fusion_kickstarted_hg19_outdir --CPU 2

kickstart_hg38:
	../STAR-Fusion --genome_lib_dir ${CTAT_GENOME_LIB}  -J __kickstart_data/hg38.Chimeric.out.junction -O star_fusion_kickstarted_hg38_outdir --CPU 2


standard:
	../STAR-Fusion --genome_lib_dir ${CTAT_GENOME_LIB}  --left_fq ${left_fq} --right_fq ${right_fq} -O star_fusion_outdir --STAR_outSAMattrRGline \'ID:testing\'


standard_run_star_only:
	../STAR-Fusion --genome_lib_dir ${CTAT_GENOME_LIB}  --left_fq ${left_fq} --right_fq ${right_fq} -O star_fusion_outdir_starOnly --run_STAR_only

all: standard \
     kickstart_hg19 \
     kickstart_hg19_evreads \
     kickstart_hg19_coding_effect \
     kickstart_hg19_FI_inspect \
     standard_denovo_reconstruct \
     standard_coding_effect \
     standard_SE \
     kickstart_hg19_SE \
     standard_run_star_only \
	 samples_PE \
     samples_PE_FI \
	 max_sensitivity \
     full_Monty




#####################################################
#### Kickstart_Hg19, starting from chimeric junctions file

kickstart_hg19_evreads: kickstart_hg19
	../STAR-Fusion -J __kickstart_data/hg19.Chimeric.out.junction --genome_lib_dir ${CTAT_GENOME_LIB}  --extract_fusion_reads --left_fq ${left_fq} --right_fq ${right_fq} -O star_fusion_kickstart_hg19ed_outdir


kickstart_hg19_coding_effect: kickstart_hg19
	../STAR-Fusion -J __kickstart_data/hg19.Chimeric.out.junction --genome_lib_dir ${CTAT_GENOME_LIB} --examine_coding_effect --left_fq ${left_fq} --right_fq ${right_fq} -O star_fusion_kickstart_hg19ed_outdir


kickstart_hg19_FI_inspect: kickstart_hg19_coding_effect
	../STAR-Fusion -J __kickstart_data/hg19.Chimeric.out.junction --genome_lib_dir ${CTAT_GENOME_LIB}  --examine_coding_effect --FusionInspector inspect --left_fq ${left_fq} --right_fq ${right_fq} -O star_fusion_kickstart_hg19ed_outdir 


###################################
#### Full mode, starting from reads


standard_denovo_reconstruct: standard
	../STAR-Fusion --genome_lib_dir ${CTAT_GENOME_LIB}  --denovo_reconstruct --FusionInspector validate --left_fq ${left_fq} --right_fq ${right_fq} -O star_fusion_outdir  

standard_coding_effect: standard
	../STAR-Fusion --genome_lib_dir ${CTAT_GENOME_LIB}  --FusionInspector validate --examine_coding_effect --left_fq ${left_fq} --right_fq ${right_fq} -O star_fusion_outdir  



####################
## use samples file:

samples_PE:
	../STAR-Fusion --genome_lib_dir ${CTAT_GENOME_LIB} --samples_file data/samples.txt  -O star_fusion_samplesPE_outdir  


samples_PE_FI: samples_PE_FI_inspect samples_PE_FI_validate


samples_PE_FI_inspect: samples_PE
	../STAR-Fusion --genome_lib_dir ${CTAT_GENOME_LIB} --samples_file data/samples.txt  -O star_fusion_samplesPE_outdir  --FusionInspector inspect

samples_PE_FI_validate: samples_PE
	../STAR-Fusion --genome_lib_dir ${CTAT_GENOME_LIB} --samples_file data/samples.txt  -O star_fusion_samplesPE_outdir  --FusionInspector validate



###############################
## single-cell fusion analysis

single_cell_PE:
	../util/sc/prep_distributed_jobs.py --sample_sheet data/samples.txt --cells_per_job 1 --output_dir star_fusion_SingleCellPE # cells_per_job set to 1 just for this smallt est. Default is actually 24
	../util/sc/write_sc_starF_cmds.py --batches_list_file star_fusion_SingleCellPE.batches.list --genome_lib_dir ${CTAT_GENOME_LIB} --use_shared_mem > star_fusion_SingleCellPE.batches.starF.cmds
	../util/sc/run_distributed_jobs_locally.py --cmds_file star_fusion_SingleCellPE.batches.starF.cmds --num_parallel_exec 4 --genome_lib_dir ${CTAT_GENOME_LIB}
	../util/sc/aggregate_and_deconvolve_fusion_outputs.py --batches_list_file star_fusion_SingleCellPE.batches.list --output_prefix star_fusion_SingleCellPE




##################################
#### Single-end reads instead of pairs

standard_SE:
	../STAR-Fusion --genome_lib_dir ${CTAT_GENOME_LIB}  --FusionInspector inspect --examine_coding_effect --left_fq ${left_fq} -O star_fusion_SE_outdir  

kickstart_hg19_SE:
	../STAR-Fusion --genome_lib_dir ${CTAT_GENOME_LIB} -J __kickstart_data/hg19.Chimeric.out.junction  --FusionInspector inspect --examine_coding_effect --left_fq ${left_fq} -O star_fusion_SE_outdir_kickstart_hg19  --STAR_use_shared_memory 


#### max sensitivity and full monty modes

max_sensitivity:
	../STAR-Fusion --genome_lib_dir ${CTAT_GENOME_LIB}  --left_fq ${left_fq} --right_fq ${right_fq} -O star_fusion_outdir.max_sens --max_sensitivity


full_Monty:
	../STAR-Fusion --genome_lib_dir ${CTAT_GENOME_LIB}  --left_fq ${left_fq} --right_fq ${right_fq} -O star_fusion_outdir.full_Monty --full_Monty  


######################
## Cleanup

clean:
	rm -rf ./star_fusion_outdir
	rm -rf ./star_fusion_kickstart_hg19ed_outdir
	rm -rf ./star_fusion_SE_outdir
	rm -rf ./star_fusion_SE_outdir_kickstart_hg19
	rm -rf ./star_fusion_bbmerge_outdir
	(rm -rf ./test_docker_outdir) || sudo rm -rf ./test_docker_outdir
	rm -rf ./star_fusion_samplesPE_outdir
	rm -rf ./star_fusion_outdir_starOnly
	rm -rf ./test_singularity_outdir
	rm -rf ./star_fusion_SingleCellPE*
	rm -rf ./star_fusion_outdir.full_Monty
	rm -rf ./star_fusion_outdir.max_sens


purge:
	../STAR-Fusion --STAR_Remove

