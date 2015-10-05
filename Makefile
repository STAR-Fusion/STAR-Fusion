
blast_pairs_idx=resources/blast_pairs.idx
blast_pairs_outfmt6=resources/gencode.v19.annotation.cdna.blast_pairs.gz

all: ${blast_pairs_idx}


${blast_pairs_idx}: ${blast_pairs_outfmt6} 
	@echo
	@echo
	@echo "Indexing blast pair info..."
	./FusionFilter/util/index_blast_pairs.pl ${blast_pairs_outfmt6} ${blast_pairs_idx}
	@echo "Done."
	@echo
	@echo



clean:
	rm -f resources/blast_pairs.idx
	cd example/ && ./cleanme.pl


test:
	cd example/ && runMe.sh
