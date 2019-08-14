#!/bin/bash

set -ev

VERSION=`cat VERSION.txt`

docker push bhaastestdockers/starfusion:${VERSION}


