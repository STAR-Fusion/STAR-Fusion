#! /usr/bin/env python

# bedpe described: https://www.synapse.org/#!Synapse:syn2813589/wiki/401442

import sys
import csv

usage = "\n\tusage: {} star_fusion.abridged.tsv\n\n".format(sys.argv[0])

if len(sys.argv) < 2:
    exit(usage)

input_file = sys.argv[1]

with open(input_file, "rt") as fh:
    reader = csv.DictReader(fh, delimiter="\t")
    for row in reader:
        valsL = row['LeftBreakpoint'].split(':')
        valsR = row['RightBreakpoint'].split(':')
        chrL = valsL[0]
        posL = valsL[1]
        geneL = row['LeftGene'].split('^')[0]
        strandL = valsL[2]
        chrR = valsR[0]
        posR = valsR[1]
        geneR = row['RightGene'].split('^')[0]
        strandR = valsR[2]
        bedpe = '\t'.join([chrL, str(int(posL)-1), posL, chrR, str(int(posR)-1), posR,'-'.join([geneL, geneR]), '0', strandL, strandR])
        print(bedpe)
        
sys.exit(0)

