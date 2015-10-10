#!/bin/bash

if [ ! $CTAT_GENOME_LIB ]; then
    echo Before running 'runMe.sh', you must set env var CTAT_GENOME_LIB to your genome_lib_dir resource directory path.
    exit 1
fi

## set genome_lib_dir (see: http://FusionFilter.github.io for details)

../STAR-Fusion -J __kickstart_data/Chimeric.out.junction -O star_fusion_kickstarted_outdir --genome_lib_dir $CTAT_GENOME_LIB --verbose_level 2



