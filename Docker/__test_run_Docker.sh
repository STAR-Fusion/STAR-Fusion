#!/bin/bash

set -ve

if [ -z ${CTAT_GENOME_LIB} ]; then
    echo "Error, must have CTAT_GENOME_LIB env var set"
    exit 1
fi


VERSION=`cat VERSION.txt`

# run STAR-Fusion
docker run -v `pwd`/../:/data -v ${CTAT_GENOME_LIB}:/ctat_genome_lib --rm trinityctat/starfusion:${VERSION} /usr/local/src/STAR-Fusion/STAR-Fusion --left_fq /data/testing/reads_1.fq.gz --right_fq /data/testing/reads_2.fq.gz --genome_lib_dir /ctat_genome_lib -O /data/testing/test_docker_outdir/StarFusionOut --FusionInspector inspect --examine_coding_effect --denovo_reconstruct

