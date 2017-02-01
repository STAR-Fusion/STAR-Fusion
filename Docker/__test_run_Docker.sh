#!/bin/bash

set -ve

CTAT_GENOME_LIB="GRCh37_gencode_v19_CTAT_lib_July272016"

CTAT_GENOME_LIB_URL="https://data.broadinstitute.org/Trinity/CTAT_RESOURCE_LIB/GRCh37_gencode_v19_CTAT_lib_July272016.tar.gz"


if [ ! -s "${CTAT_GENOME_LIB}.tar.gz" ]; then
    wget ${CTAT_GENOME_LIB_URL}
fi

if [ ! -d "${CTAT_GENOME_LIB}" ]; then
    tar xvf "${CTAT_GENOME_LIB}.tar.gz"
fi


VERSION=`cat VERSION.txt`

docker pull trinityctat/ctatfusion:${VERSION}

