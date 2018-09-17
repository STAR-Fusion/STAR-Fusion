#!/bin/bash

set -ev

VERSION=`cat VERSION.txt`

docker build -t trinityctat/ctatfusion:${VERSION} .
#docker build -t trinityctat/ctatfusion:latest .

