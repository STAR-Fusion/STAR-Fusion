#!/bin/bash

set -ev

VERSION=`cat VERSION.txt`

docker push trinityctat/ctatfusion:${VERSION}



