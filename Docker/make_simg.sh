#!/bin/bash

VERSION=`cat VERSION.txt`

singularity build star-fusion.v${VERSION}.simg docker://trinityctat/starfusion:$VERSION

singularity exec star-fusion.v${VERSION}.simg /usr/local/src/STAR-Fusion/STAR-Fusion --version
