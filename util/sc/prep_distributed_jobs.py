#!/usr/bin/env python

import sys, os, re
import argparse


def main():

    parser = argparse.ArgumentParser(description="splits sample sheets and generates STAR-Fusion commands",
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument("--sample_sheet", required=True, help="sample sheet")
    parser.add_argument("--cells_per_job", required=False, type=int, default=24, help="number of cells per run")
    parser.add_argument("--output_dir", required=True, type=str, help="output directory")


    args = parser.parse_args()

    sample_sheet = args.sample_sheet
    cells_per_job = args.cells_per_job
    output_dir = args.output_dir

    output_dir = os.path.abspath(output_dir)
    
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    batch_files = list()
    batch_num = 0
    sample_counter = 0
    ofh = None

    with open(sample_sheet, 'rt') as fh:
        for line in fh:
            line = line.rstrip()
    
            if sample_counter % cells_per_job == 0: # should always trigger on first entry
                if ofh:
                    ofh.close
                batch_num += 1
                batch_file = os.path.join(output_dir, "batch.{}.sample_sheet".format(batch_num))
                ofh = open(batch_file, 'wt')
                batch_files.append(batch_file)
                
            print(line, file=ofh)
            sample_counter += 1
                    
    ofh.close
    
    # write sample sheet listing.
    batches_list_file = output_dir + ".batches.list"
    with open(batches_list_file, 'wt') as ofh:
        ofh.write("\n".join(batch_files) + "\n")


    sys.exit(0)



if __name__=='__main__':
    main()

    
