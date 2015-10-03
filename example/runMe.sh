#!/bin/bash

## set genome_lib_dir (see: http://FusionFilter.github.io for details)

../STAR-Fusion --left_fq reads_1.fq.gz --right_fq reads_2.fq.gz -O star_fusion_outdir --genome_lib_dir $CTAT_GENOME_LIB --verbose_level 2



