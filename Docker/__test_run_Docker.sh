#!/bin/bash

set -ve

CTAT_GENOME_LIB="GRCh37_v19_CTAT_lib_Feb092018"

CTAT_GENOME_LIB_URL="https://data.broadinstitute.org/Trinity/CTAT_RESOURCE_LIB/__genome_libs_StarFv1.3/GRCh37_v19_CTAT_lib_Feb092018.plug-n-play.tar.gz"


if [ ! -s "../${CTAT_GENOME_LIB}.tar.gz" ]; then
    wget ${CTAT_GENOME_LIB_URL} -O ../${CTAT_GENOME_LIB}.tar.gz
fi


if [ ! -d "../${CTAT_GENOME_LIB}" ]; then
    tar xvf ../${CTAT_GENOME_LIB}.tar.gz -C ../.
fi


VERSION=`cat VERSION.txt`

# run STAR-Fusion
docker run -v `pwd`/../:/data --rm trinityctat/ctatfusion:${VERSION} /usr/local/src/STAR-Fusion/STAR-Fusion --left_fq /data/testing/reads_1.fq.gz --right_fq /data/testing/reads_2.fq.gz --genome_lib_dir /data/${CTAT_GENOME_LIB}/ctat_genome_lib_build_dir -O /data/testing/test_docker_outdir/StarFusionOut --FusionInspector inspect --examine_coding_effect --denovo_reconstruct

