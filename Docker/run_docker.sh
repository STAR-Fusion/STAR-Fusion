#!/bin/bash

docker run --rm -it -v `pwd`:`pwd` trinityctat/starfusion:latest $*

