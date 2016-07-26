test:
	../../../STAR-Fusion -J Chimeric.out.junction.gz --genome_lib_dir ${CTAT_GENOME_LIB} -O outdir
	diff __star-fusion.fusion_candidates.final.abridged outdir/star-fusion.fusion_candidates.final.abridged

clean:
	rm -rf ./outdir
