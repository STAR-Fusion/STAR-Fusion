#!/bin/bash

set -ev

docker build -t localhost:6000/trinctatfusion:devel .

docker push localhost:6000/trinctatfusion:devel

sudo SINGULARITY_NOHTTPS=1 singularity build starfusion.devel.simg docker://localhost:6000/trinctatfusion:devel

