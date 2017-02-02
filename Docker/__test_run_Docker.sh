#!/bin/bash

set -ve

CTAT_GENOME_LIB="GRCh37_gencode_v19_CTAT_lib_July272016_prebuilt"

CTAT_GENOME_LIB_URL="https://data.broadinstitute.org/Trinity/CTAT_RESOURCE_LIB/${CTAT_GENOME_LIB}.tar.gz"


if [ ! -s "../${CTAT_GENOME_LIB}.tar.gz" ]; then
    wget ${CTAT_GENOME_LIB_URL} -O ../${CTAT_GENOME_LIB}.tar.gz
fi

if [ ! -d "../${CTAT_GENOME_LIB}" ]; then
    tar xvf "../${CTAT_GENOME_LIB}.tar.gz"
fi


VERSION=`cat VERSION.txt`

# run STAR-Fusion
docker run -v `pwd`/../:/data --rm trinityctat/ctatfusion:${VERSION} /usr/local/src/STAR-Fusion-v1.0.0/STAR-Fusion --left_fq /data/testing/reads_1.fq.gz --right_fq /data/testing/reads_2.fq.gz --genome_lib_dir /data/GRCh37_gencode_v19_CTAT_lib_July272016_prebuilt -O /data/testing/test_docker_outdir/StarFusionOut


# run FusionInspector
docker run -v `pwd`/../:/data --rm trinityctat/ctatfusion:${VERSION} /usr/local/src/FusionInspector-v1.0.1/FusionInspector --fusions /data/testing/test_docker_outdir/StarFusionOut/star-fusion.fusion_candidates.final.abridged.FFPM --left_fq /data/testing/reads_1.fq.gz --right_fq /data/testing/reads_2.fq.gz --genome_lib /data/GRCh37_gencode_v19_CTAT_lib_July272016_prebuilt --out_prefix finspector --out_dir /data/testing/test_docker_outdir/FusionInspectorOut --include_Trinity

