#!/usr/bin/env perl

use strict;
use warnings;

use Cwd;

my $curr_dir = cwd();

my $exit_code = 0;

foreach my $file (<*_1.*fastq*>, <*_1*.fq*>) {

    $file =~ /^(\S+)_1\.*/ or die "Error, cannot decipher filename $file";
    my $core = $1;

    my $right_fq = $file;
    $right_fq =~ s/_1\./_2\./;
    
    unless (-s $right_fq) {
        print STDERR "Error, cannot find Right.fq file corresponding to $file";
        $exit_code++;
        next;
    }

    print join("\t", $core, "$curr_dir/$file", "$curr_dir/$right_fq") . "\n";

}


exit($exit_code);


    
