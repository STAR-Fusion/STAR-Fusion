#!/usr/bin/env python

import sys, os, re
import argparse
import subprocess
import logging


logging.basicConfig(stream=sys.stderr, level=logging.INFO)
logger = logging.getLogger(__name__)


def main():


    parser = argparse.ArgumentParser(description="aggregates and deconvolves fusion results from single cell outputs", formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument("--batches_list_file", type=str, required=True, help="file containing the list of sample batches")
    
    parser.add_argument("--output_prefix", type=str, required=True, help="output filename prefix for deconvolved fusions (will result in prefix.fusions.tsv and prefix.fusions.abridged.tsv")

    args = parser.parse_args()


    batches_list_file = args.batches_list_file
    output_filename = args.output_prefix + ".fusions.tsv"
    
    UTILDIR = os.path.dirname(os.path.dirname(__file__))
    
    ofh = open(output_filename, 'wt')
        
    printed_header = False

    num_batches = subprocess.check_output("wc -l {}".format(batches_list_file), shell=True).decode().split(" ")[0]
    logger.info("-there are {} batched outputs to deconvolve.".format(num_batches))

    
    
    with open(batches_list_file, 'rt') as fh:

        counter = 0
        
        for batch in fh:
            batch = batch.rstrip()

            output_dir = batch.replace(".sample_sheet", "star-fusion.outdir")
            star_fusion_output_file = os.path.join(output_dir, "star-fusion.fusion_predictions.tsv")

            counter += 1
            logger.info("-processing [{}] {}".format(counter, star_fusion_output_file))
            
            if not os.path.exists(star_fusion_output_file):
                raise RuntimeError("Error, missing expected output file: {}".format(star_fusion_output_file))
            
            # deconvolve single cell data:
            deconvolved_file = star_fusion_output_file + ".deconvolved"
            cmd = str(os.path.join(UTILDIR, "sc/starF_partition_final_by_sc.pl") +
                      " {} > {} ".format(star_fusion_output_file, deconvolved_file) )
            
            subprocess.check_call(cmd, shell=True)

            with open(deconvolved_file, 'rt') as ofh2:
                header = next(ofh2)
                if not printed_header:
                    ofh.write(header)
                    printed_header = True

                for line in ofh2:
                    ofh.write(line)

    ofh.close()
    logger.info("-wrote complete file: {}".format(output_filename))    

    logger.info("-writing abridged version now...")
    # make abridged version
    abridged_fusions_file = args.output_prefix + ".abridged.tsv"
    cmd = str( os.path.join(UTILDIR, "$UTILDIR/column_exclusions.pl {} JunctionReads,SpanningFrags > {}".format(output_filename, abridged_fusions_file)))
    subprocess.check_call(cmd, shell=True)

    logger.info("-done.  Abridged file as: {}".format(abridged_fusions_file))
    
    
    sys.exit(0)


if __name__=='__main__':
    main()
