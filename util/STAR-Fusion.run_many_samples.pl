#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use Process_cmd;

my $usage = "\n\n\tusage: $0 samples.txt\n\n";

if (! $ENV{CTAT_GENOME_LIB}) {
    die "Error, no env var set for CTAT_GENOME_LIB";
}

my $samples_file = $ARGV[0] or die $usage;


main: {

    my $star_fusion_prog = "$FindBin::Bin/../STAR-Fusion";
    
    # load the genome into memory:
    my $cmd = "$star_fusion_prog  --STAR_LoadAndExit";
    &process_cmd($cmd);


    # process samples individually
    my $counter = 0;
    open(my $fh, $samples_file) or die "Error, cannot open file: $samples_file";
    while (<$fh>) {
        chomp;
        my ($sample_name, $left_fq, $right_fq) = split(/\t/);
        $counter++;
        my $time_start = time();
        print STDERR "-processing sample[$counter]: $sample_name\n";
        my $cmd = "$star_fusion_prog --STAR_use_shared_memory --left_fq $left_fq ";
        if ($right_fq) {
            $cmd .= " --right_fq $right_fq ";
        }
        $cmd .= " -O $sample_name.starF";
        &process_cmd($cmd);
    

        my $time_end = time();
        my $minutes = ($time_end - $time_start) / 60;
        print STDERR "-sample $sample_name took $minutes min.\n\n";
    }
    close $fh;
    
    
    # unload the genome from memory
    $cmd = "$star_fusion_prog  --STAR_Remove ";
    &process_cmd($cmd);


    print STDERR "-done.\n\n";
    exit(0);
}
    
