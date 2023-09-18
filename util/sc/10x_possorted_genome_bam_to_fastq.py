#!/usr/bin/env python3

import sys, os, re
import pysam
import csv
import logging

logging.basicConfig(stream=sys.stderr, level=logging.INFO)
logger = logging.getLogger(__name__)


def main():

    usage = "\n\n\tusage: {}  10x.possorted_genome.bam\n\n".format(sys.argv[0])
    if len(sys.argv) < 2:
        exit(usage)

    bam = sys.argv[1]
        
    samreader = pysam.AlignmentFile(bam, "rb", check_sq=False)
    for read in samreader:

        if read.is_secondary:
            continue

        if read.is_supplementary:
            continue
        
        d = read.to_dict()
        
        read_name = d['name']
        read_seq = d['seq']
        quals = d['qual']

        # 10x tag descriptions at:
        # https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/output/bam#:~:text=Barcoded%20BAM%20Tags,-The%20cellranger%20pipeline%20outputs%20an

        CB = "NA"
        if read.has_tag("CB"):
            cell_barcode = read.get_tag("CB", "Z")[0]
            cell_barcode = re.sub("-1$", "", cell_barcode)

        umi = "NA"
        if read.has_tag("UB"):
            umi = read.get_tag("UB", "Z")[0]

        
        read_name = "^".join([cell_barcode, umi, read_name])
        
        print("\n".join(["@" + read_name,
                         read_seq,
                         "+",
                         quals]))
        


    sys.exit(0)
    


if __name__=='__main__':
    main()
