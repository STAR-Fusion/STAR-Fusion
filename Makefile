
resources/gencode.v19.annotation.gtf.exons.cdna.gz.idx: resources/gencode.v19.annotation.gtf.exons.cdna.gz
	@echo "\n\nIndexing transcriptome seqs...\n\n"
	 util/index_cdna_seqs.pl resources/gencode.v19.annotation.gtf.exons.cdna.gz
	@echo "Done.\n\n"


resources/gencode.v19.annotation.gtf.exons.cdna.gz.blastn_gene_pairs.gz.idx: resources/gencode.v19.annotation.gtf.exons.cdna.gz.blastn_gene_pairs.gz
	@echo "\n\nIndexing blast pair info...\n\n"
	 util/index_blast_pairs.pl resources/gencode.v19.annotation.gtf.exons.cdna.gz.blastn_gene_pairs
	@echo "Done.\n\n"

