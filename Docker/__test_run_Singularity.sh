#!/bin/bash

set -ve

## assumes we already ran/tested the Docker image



CTAT_GENOME_LIB="GRCh37_gencode_v19_CTAT_lib_Aug152019.plug-n-play"


VERSION=`cat VERSION.txt`

# run STAR-Fusion
cd ../ && singularity exec Docker/star-fusion.v${VERSION}.simg  /usr/local/src/STAR-Fusion/STAR-Fusion --left_fq testing/reads_1.fq.gz --right_fq testing/reads_2.fq.gz --genome_lib_dir ${CTAT_GENOME_LIB}/ctat_genome_lib_build_dir -O testing/test_singularity_outdir/StarFusionOut --FusionInspector inspect --examine_coding_effect --denovo_reconstruct

