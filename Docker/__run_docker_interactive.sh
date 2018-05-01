#!/bin/bash

set -ve

CTAT_GENOME_LIB="GRCh37_v19_CTAT_lib_Feb092018"


VERSION=`cat VERSION.txt`

# run STAR-Fusion
docker run --rm -it -v `pwd`/../:/data --rm trinityctat/ctatfusion:${VERSION} bash 

