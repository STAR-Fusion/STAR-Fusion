


standard:
	./__misc_tests/runMe.sh


all: standard kickstart kickstart_evreads denovo_reconstruct


kickstart:
	./__misc_tests/runMe.kickstart.sh

kickstart_evreads: kickstart
	./__misc_tests/runMe.kickstart.sh --extract_fusion_reads

kickstart_annotate: kickstart
	./__misc_tests/runMe.kickstart.sh --annotate

kickstart_coding_effect: kickstart_annotate
	./__misc_tests/runMe.kickstart.sh --examine_coding_effect

denovo_reconstruct:
	./__misc_tests/runMe.denovo_reconstruct.sh


clean:
	rm -rf ./star_fusion_outdir
	rm -rf ./star_fusion_kickstarted_outdir
