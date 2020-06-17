#!/usr/bin/env python

import sys, os, re
import argparse


def main():


    parser = argparse.ArgumentParser(description="generate STAR-Fusion commands for each batch of cells", formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument("--batches_list_file", type=str, required=True, help="file containing the list of sample batches")
    parser.add_argument("--genome_lib_dir", type=str, required=True, help="path to the ctat genome lib dir")

    args, unknown_args = parser.parse_known_args()

    batches_list_file = args.batches_list_file
    ctat_genome_lib_dir = args.genome_lib_dir


    STAR_FUSION_HOME = os.path.dirname( os.path.abspath(__file__)) + "/../.." 
    
    starF_prog = os.path.join(STAR_FUSION_HOME, "STAR-Fusion")

    with open(batches_list_file, 'rt') as fh:
        for batch in fh:
            batch = batch.rstrip()
            cmd = str(starF_prog +
                      " --genome_lib_dir {} ".format(ctat_genome_lib_dir) +
                      " --samples_file {} ".format(batch) +
                      " --max_sensitivity " +
                      " ".join(unknown_args) )

            print(cmd)
    
    sys.exit(0)


if __name__=='__main__':
    main()
