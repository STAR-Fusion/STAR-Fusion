

kickstart:
	./__misc_tests/runMe.kickstart.sh


standard:
	./__misc_tests/runMe.sh


all: standard \
     kickstart \
     kickstart_evreads \
     denovo_reconstruct \
     kickstart_annotate \
     kickstart_coding_effect \
     kickstart_FI_inspect


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

denovo_reconstruct:
	./__misc_tests/runMe.denovo_reconstruct.sh


clean:
	rm -rf ./star_fusion_outdir
	rm -rf ./star_fusion_kickstarted_outdir
