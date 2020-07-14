#!/bin/bash

set -ev

VERSION=`cat VERSION.txt`

docker build -t trinityctat/starfusion:${VERSION} .


