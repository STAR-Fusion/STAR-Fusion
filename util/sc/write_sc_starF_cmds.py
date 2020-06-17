#!/usr/bin/env python

import sys, os, re
import argparse


def main():


    parser = argparse.ArgumentParser(description="generate STAR-Fusion commands for each batch of cells", formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument("--batches_list_file", type=str, required=True, help="file containing the list of sample batches")
    parser.add_argument("--genome_lib_dir", type=str, required=True, help="path to the ctat genome lib dir")
    parser.add_argument("--use_shared_mem", action='store_true', required=False, default=False, help="use shared memory in STAR execution")

    args, unknown_args = parser.parse_known_args()

    batches_list_file = args.batches_list_file
    ctat_genome_lib_dir = args.genome_lib_dir
    use_shared_mem = args.use_shared_mem
    
    STAR_FUSION_HOME = os.path.dirname( os.path.abspath(__file__)) + "/../.." 
    
    starF_prog = os.path.join(STAR_FUSION_HOME, "STAR-Fusion")

    with open(batches_list_file, 'rt') as fh:
        for batch in fh:
            batch = batch.rstrip()

            output_dir = batch.replace(".sample_sheet", ".star-fusion.outdir")
            
            cmd = str(starF_prog +
                      " --genome_lib_dir {} ".format(ctat_genome_lib_dir) +
                      " --samples_file {} ".format(batch) +
                      " --max_sensitivity " +
                      " --output_dir {} ".format(output_dir) +
                      " ".join(unknown_args) )

            if use_shared_mem:
                cmd += " --STAR_use_shared_memory "
                


            print(cmd)
    
    sys.exit(0)


if __name__=='__main__':
    main()
