#!/bin/bash

VERSION=`cat VERSION.txt`

singularity build star-fusion.v${VERSION}.simg docker://bhaastestdockers/starfusion:$VERSION


