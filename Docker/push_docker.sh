#!/bin/bash

set -ev

VERSION=`cat VERSION.txt`

docker push trinityctat/starfusion:${VERSION}
docker push trinityctat/starfusion:latest



