#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../../PerlLib");
use Process_cmd;
use File::Basename;



use Getopt::Long qw(:config posix_default no_ignore_case bundling pass_through);

my $usage = <<__EOUSAGE__;

########################################################################################
#
# --A_fusions <string>      aggregated fusions dat file A
#
# --B_fusions <string>      aggregated fusions dat file B
#
# --out_prefix <string>     prefix for output file
#
########################################################################################


__EOUSAGE__

    ;


my $help_flag;
my $A_tsv;
my $B_tsv;
my $out_prefix;

my $utildir = "$FindBin::Bin";


&GetOptions (
    'h' => \$help_flag,
    'A_fusions=s' => \$A_tsv,
    'B_fusions=s' => \$B_tsv,
    'out_prefix=s' => \$out_prefix,
    );

unless ($A_tsv && $B_tsv) {
    die $usage;
}



main: {

    for my $val_type ("FFPM", "J", "S", "T") {
        
        
        eval {
            my $dat_file = "$out_prefix.__${val_type}__.dat";
            
            my $cmd = "$utildir/contrast_fusion_calls.extract_table.pl "
                . " --A_fusions $A_tsv "
                . " --B_fusions $B_tsv "
                . " --val_type $val_type > $dat_file";
            
            &process_cmd($cmd);
            
            $cmd = "$utildir/contrast_fusion_calls.scatterplot.Rscript $dat_file";
            &process_cmd($cmd);
                        
        };

    }
    
    exit(0);
    
}

