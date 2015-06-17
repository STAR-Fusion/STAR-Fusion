
resources/gencode.v19.annotation.gtf.exons.cdna.gz.idx: resources/gencode.v19.annotation.gtf.exons.cdna.gz
	@echo "\n\nIndexing transcriptome seqs...\n\n"
	 util/index_cdna_seqs.pl resources/gencode.v19.annotation.gtf.exons.cdna.gz
	@echo "Done.\n\n"

