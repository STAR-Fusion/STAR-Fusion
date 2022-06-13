#!/usr/bin/env python3

import sys, os, re
import pandas as pd


usage = "\n\tusage: {} fusions.tsv\n\n".format(sys.argv[0])

if len(sys.argv) < 2:
    exit(usage)

fusions_tsv = sys.argv[1]
    
df = pd.read_csv(fusions_tsv, sep="\t")


def extract_brkpt_info(brkpt_info):
    
    chrom, coord, orient = brkpt_info.split(":")

    coord = int(coord)
    
    if (orient == '+'):
        coordA = coord - 1
        coordB = coord
    else:
        coordA = coord
        coordB = coord + 1
    
    return (chrom, coordA, coordB)


left_brk_info = df['LeftBreakpoint'].apply(extract_brkpt_info)
left_brk_pd = pd.DataFrame(left_brk_info.tolist(), columns=['chr1', 'start1', 'end1'])

right_brk_info = df['RightBreakpoint'].apply(extract_brkpt_info)
right_brk_pd = pd.DataFrame(right_brk_info.tolist(), columns=['chr2', 'start2', 'end2'])

out_df = pd.concat([left_brk_pd, right_brk_pd], axis=1)
out_df.to_csv(f"{fusions_tsv}.for_circos.tsv", sep="\t", index=False)

sys.exit(0)

