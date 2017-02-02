#!/bin/bash

set -ve

CTAT_GENOME_LIB="GRCh37_gencode_v19_CTAT_lib_July272016_prebuilt"

CTAT_GENOME_LIB_URL="https://data.broadinstitute.org/Trinity/CTAT_RESOURCE_LIB/${CTAT_GENOME_LIB}.tar.gz"


if [ ! -s "${CTAT_GENOME_LIB}.tar.gz" ]; then
    wget ${CTAT_GENOME_LIB_URL}
fi

if [ ! -d "${CTAT_GENOME_LIB}" ]; then
    tar xvf "${CTAT_GENOME_LIB}.tar.gz"
fi


VERSION=`cat VERSION.txt`

docker pull trinityctat/ctatfusion:${VERSION}

docker run -v `pwd`/../:/data --rm trinityctat/ctatfusion /usr/local/src/STAR-Fusion-v1.0.0/STAR-Fusion --left_fq /data/testing/reads_1.fq.gz --right_fq /data/testing/reads_2.fq.gz --genome_lib_dir /data/Docker/GRCh37_gencode_v19_CTAT_lib_July272016_prebuilt -O outdir
