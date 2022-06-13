#!/usr/bin/env python

import sys, os, re
import argparse
import subprocess
import logging

logging.basicConfig(stream=sys.stderr, level=logging.INFO)
logger = logging.getLogger(__name__)



def main():

    parser = argparse.ArgumentParser(
        description="generate STAR-Fusion commands for each batch of cells",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    parser.add_argument("--cmds_file", type=str, required=True, help="file containing the list of STAR-Fusion commands")
    parser.add_argument("--num_parallel_exec", type=int, required=True, help="number of STAR-Fusion commands to run in parallel")
    parser.add_argument("--genome_lib_dir", type=str, required=True, help="path to ctat genome lib dir")
    parser.add_argument("--unload_genome_at_end", action='store_true', default=False, help="unload the genome from shared memory once all jobs complete")


    args = parser.parse_args()

    cmds_file = args.cmds_file
    num_parallel = args.num_parallel_exec
    genome_lib_dir = args.genome_lib_dir
    unload_genome_at_end_flag = args.unload_genome_at_end


    ensure_parafly_installed()
    

    logger.info("-loading genome into shared mem")

    star_fusion_prog = os.path.join( os.path.dirname(os.path.abspath(__file__)), "../../STAR-Fusion")

    genome_preload_cmd = str(star_fusion_prog +
                             " --genome_lib_dir {} ".format(genome_lib_dir) +
                             " --STAR_LoadAndExit ")
    subprocess.check_call(genome_preload_cmd, shell=True)

    logger.info("-done preloading genome.  Now, running STAR-Fusion commands.")

    


    cmd = "ParaFly -c {} -CPU {} -vv -max_retry 1".format(cmds_file, num_parallel)
    subprocess.check_call(cmd, shell=True)

    logger.info("-done running parallel commands.")

    if unload_genome_at_end_flag:

        logger.info("-unloading genome from shared memory")

        cmd = str(star_fusion_prog +
                  " --genome_lib_dir {} ".format(genome_lib_dir) +
                  " --STAR_Remove ")

        subprocess.check_call(cmd, shell=True)


    logger.info("done")
    
    sys.exit(0)
    

def ensure_parafly_installed():

    try:
        subprocess.check_call("which ParaFly", shell=True)
    except:
        raise RuntimeError("Erorr, cannot find ParaFly installed and available in the PATH setting.  Be sure to install ParaFly before running")

    return


    
if __name__=="__main__":
    main()

