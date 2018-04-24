#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use Cwd;

my $usage = "\n\n\tusage: $0 samples.txt\n\n";

my $samples_file = $ARGV[0] or die $usage;

my $workdir = cwd();

main: {

    open(my $fh, $samples_file) or die "error, cannot open file $samples_file";
    while(<$fh>) {
        chomp;
        my ($sample_name, $left_fq, $right_fq) = split(/\s+/);

        my $cmd = "$FindBin::Bin/../../STAR-Fusion --left_fq $left_fq --right_fq $right_fq --output_dir $workdir/$sample_name --bbmerge";

        print "$cmd\n";

    }
    close $fh;

    exit(0);
}


        

 
    
