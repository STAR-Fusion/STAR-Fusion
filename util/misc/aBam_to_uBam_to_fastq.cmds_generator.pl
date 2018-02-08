#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use FindBin;

# generate the list of commands that can be run in parallel on the compute farm

my $usage = "usage: $0 fileA.bam fileB.bam ...\n\n";

my @bam_files = @ARGV or die $usage;


my $util = "$FindBin::Bin/aBam_to_uBam_to_fastq.pl"; # does the work 

foreach my $file (@bam_files) {

    my $cmd = "$util $file\n";
    print $cmd;
}

exit(0);


    
