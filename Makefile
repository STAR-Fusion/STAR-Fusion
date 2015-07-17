
all : resources/gencode.v19.annotation.gtf.exons.cdna.gz.idx resources/gencode.v19.annotation.gtf.exons.cdna.gz.blastn_gene_pairs.gz.idx


resources/gencode.v19.annotation.gtf.exons.cdna.gz.idx: resources/gencode.v19.annotation.gtf.exons.cdna.gz
	@echo
	@echo
	@echo "Indexing transcriptome seqs..."
	util/index_cdna_seqs.pl resources/gencode.v19.annotation.gtf.exons.cdna.gz	
	@echo "Done."
	@echo
	@echo


resources/gencode.v19.annotation.gtf.exons.cdna.gz.blastn_gene_pairs.gz.idx: resources/gencode.v19.annotation.gtf.exons.cdna.gz.blastn_gene_pairs.gz
	@echo
	@echo
	@echo "Indexing blast pair info..."
	util/index_blast_pairs.pl resources/gencode.v19.annotation.gtf.exons.cdna.gz.blastn_gene_pairs.gz
	@echo "Done."
	@echo
	@echo



clean:
	rm -f resources/gencode.v19.annotation.gtf.exons.cdna.gz.idx
	rm -f resources/gencode.v19.annotation.gtf.exons.cdna.gz.blastn_gene_pairs.gz.idx
	cd example/ && ./cleanme.pl


test:
	cd example/ && runMe.pl
