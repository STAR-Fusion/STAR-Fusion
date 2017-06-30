


standard:
	./__misc_tests/runMe.sh


all: standard kickstart kickstart_evreads denovo_reconstruct


kickstart:
	./__misc_tests/runMe.kickstart.sh

kickstart_evreads:
	./__misc_tests/runMe.kickstart.extract_fusion_reads.sh

denovo_reconstruct:
	./__misc_tests/runMe.denovo_reconstruct.sh


clean:
	rm -rf ./star_fusion_outdir
	rm -rf ./star_fusion_kickstarted_outdir
