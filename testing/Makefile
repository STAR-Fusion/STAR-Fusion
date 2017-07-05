

kickstart:
	./__misc_tests/runMe.kickstart.sh


standard:
	./__misc_tests/runMe.sh


all: standard \
     kickstart \
     kickstart_evreads \
     kickstart_annotate \
     kickstart_coding_effect \
     kickstart_FI_inspect \
     standard_denovo_reconstruct \
     standard_annotate \
     standard_coding_effect


#####################################################
#### Kickstart, starting from chimeric junctions file

kickstart_evreads: kickstart
	./__misc_tests/runMe.kickstart.sh --extract_fusion_reads

kickstart_annotate: kickstart
	./__misc_tests/runMe.kickstart.sh --annotate

kickstart_coding_effect: kickstart_annotate
	./__misc_tests/runMe.kickstart.sh --examine_coding_effect --annotate


kickstart_FI_inspect: kickstart_coding_effect
	./__misc_tests/runMe.kickstart.sh --examine_coding_effect --annotate --FusionInspector inspect


###################################
#### Full mode, starting from reads

standard_denovo_reconstruct: standard
	./__misc_tests/runMe.sh --denovo_reconstruct --FusionInspector validate 

standard_annotate: standard
	./__misc_tests/runMe.sh --FusionInspector validate --annotate 

standard_coding_effect: standard_annotate
	./__misc_tests/runMe.sh --FusionInspector validate --annotate --examine_coding_effect



clean:
	rm -rf ./star_fusion_outdir
	rm -rf ./star_fusion_kickstarted_outdir
