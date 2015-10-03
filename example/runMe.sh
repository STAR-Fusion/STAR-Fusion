#!/bin/bash

## set genome_lib_dir (see: http://FusionFilter.github.io for details)

../STAR-Fusion -J Chimeric.out.junction.gz --genome_lib_dir $CTAT_GENOME_LIB --verbose_level 2

