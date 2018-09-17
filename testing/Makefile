

left_fq="reads_1.fq.gz"
right_fq="reads_2.fq.gz"


kickstart:
	../STAR-Fusion --genome_lib_dir ${CTAT_GENOME_LIB}  -J __kickstart_data/Chimeric.out.junction -O star_fusion_kickstarted_outdir 


standard:
	../STAR-Fusion --genome_lib_dir ${CTAT_GENOME_LIB}  --left_fq ${left_fq} --right_fq ${right_fq} -O star_fusion_outdir --STAR_use_shared_memory 


standard_run_star_only:
	../STAR-Fusion --genome_lib_dir ${CTAT_GENOME_LIB}  --left_fq ${left_fq} --right_fq ${right_fq} -O star_fusion_outdir_starOnly --STAR_use_shared_memory --run_STAR_only

all: standard \
     kickstart \
     kickstart_evreads \
     kickstart_coding_effect \
     kickstart_FI_inspect \
     standard_denovo_reconstruct \
     standard_coding_effect \
     standard_SE \
     kickstart_SE \
     standard_run_star_only \
	 samples_PE \
     samples_PE_FI




#####################################################
#### Kickstart, starting from chimeric junctions file

kickstart_evreads: kickstart
	../STAR-Fusion -J __kickstart_data/Chimeric.out.junction --genome_lib_dir ${CTAT_GENOME_LIB}  --extract_fusion_reads --left_fq ${left_fq} --right_fq ${right_fq} -O star_fusion_kickstarted_outdir


kickstart_coding_effect: kickstart
	../STAR-Fusion -J __kickstart_data/Chimeric.out.junction --genome_lib_dir ${CTAT_GENOME_LIB} --examine_coding_effect --left_fq ${left_fq} --right_fq ${right_fq} -O star_fusion_kickstarted_outdir


kickstart_FI_inspect: kickstart_coding_effect
	../STAR-Fusion -J __kickstart_data/Chimeric.out.junction --genome_lib_dir ${CTAT_GENOME_LIB}  --examine_coding_effect --FusionInspector inspect --left_fq ${left_fq} --right_fq ${right_fq} -O star_fusion_kickstarted_outdir 


###################################
#### Full mode, starting from reads

standard_denovo_reconstruct: standard
	../STAR-Fusion --genome_lib_dir ${CTAT_GENOME_LIB}  --denovo_reconstruct --FusionInspector validate --left_fq ${left_fq} --right_fq ${right_fq} -O star_fusion_outdir  --STAR_use_shared_memory 

standard_coding_effect: standard
	../STAR-Fusion --genome_lib_dir ${CTAT_GENOME_LIB}  --FusionInspector validate --examine_coding_effect --left_fq ${left_fq} --right_fq ${right_fq} -O star_fusion_outdir  --STAR_use_shared_memory 


####################
## use samples file:

samples_PE:
	../STAR-Fusion --genome_lib_dir ${CTAT_GENOME_LIB} --samples_file data/samples.txt  -O star_fusion_samplesPE_outdir  --STAR_use_shared_memory 


samples_PE_FI: samples_PE_FI_inspect samples_PE_FI_validate


samples_PE_FI_inspect: samples_PE
	../STAR-Fusion --genome_lib_dir ${CTAT_GENOME_LIB} --samples_file data/samples.txt  -O star_fusion_samplesPE_outdir  --STAR_use_shared_memory --FusionInspector inspect

samples_PE_FI_validate: samples_PE
	../STAR-Fusion --genome_lib_dir ${CTAT_GENOME_LIB} --samples_file data/samples.txt  -O star_fusion_samplesPE_outdir  --STAR_use_shared_memory --FusionInspector validate





##################################
#### Single-end reads instead of pairs

standard_SE:
	../STAR-Fusion --genome_lib_dir ${CTAT_GENOME_LIB}  --FusionInspector inspect --examine_coding_effect --left_fq ${left_fq} -O star_fusion_SE_outdir  --STAR_use_shared_memory 

kickstart_SE:
	../STAR-Fusion --genome_lib_dir ${CTAT_GENOME_LIB} -J __kickstart_data/Chimeric.out.junction  --FusionInspector inspect --examine_coding_effect --left_fq ${left_fq} -O star_fusion_SE_outdir_kickstart  --STAR_use_shared_memory 



######################
## Cleanup

clean:
	rm -rf ./star_fusion_outdir
	rm -rf ./star_fusion_kickstarted_outdir
	rm -rf ./star_fusion_SE_outdir
	rm -rf ./star_fusion_SE_outdir_kickstart
	rm -rf ./star_fusion_bbmerge_outdir
	(rm -rf ./test_docker_outdir) || sudo rm -rf ./test_docker_outdir
	rm -rf ./star_fusion_samplesPE_outdir
	rm -rf ./star_fusion_outdir_starOnly

purge:
	../STAR-Fusion --STAR_Remove

