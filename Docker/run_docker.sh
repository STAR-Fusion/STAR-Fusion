#!/bin/bash

docker run --rm -it -v `pwd`:`pwd` trinityctat/ctatfusion:latest $*

