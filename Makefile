
blast_pairs_idx=resources/blast_pairs.idx
blast_pairs_outfmt6=resources/gencode.v19.annotation.cdna.blast_pairs.gz

ref_annot_gtf_gz=resources/ref_annot.gtf.gz
ref_annot_gtf=resources/ref_annot.gtf

all: ${blast_pairs_idx} ${ref_annot_gtf}

${ref_annot_gtf}: ${ref_annot_gtf_gz}
	@echo
	@echo
	@echo "## gunzip-ing ${ref_annot_gtf_gz}"
	gunzip -c ${ref_annot_gtf_gz} > ${ref_annot_gtf}
	@echo "Done"
	@echo
	@echo

${blast_pairs_idx}: ${blast_pairs_outfmt6} 
	@echo
	@echo
	@echo "## Indexing blast pair info..."
	./FusionFilter/util/index_blast_pairs.pl ${blast_pairs_outfmt6} ${blast_pairs_idx}
	@echo "Done."
	@echo
	@echo



clean:
	rm -f resources/blast_pairs.idx
	cd example/ && ./cleanme.sh


test:
	cd example/ && runMe.sh
