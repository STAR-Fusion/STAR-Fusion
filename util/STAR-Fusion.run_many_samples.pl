#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use Process_cmd;
use File::Basename;
use Getopt::Long qw(:config posix_default no_ignore_case bundling pass_through);

my $usage = "\n\n\tusage: $0 samples.txt num_parallel [starF options passthru] [--do_remove]\n\n";

if (! $ENV{CTAT_GENOME_LIB}) {
    die "Error, no env var set for CTAT_GENOME_LIB";
}

my $do_remove;
&GetOptions ( 'do_remove' => \$do_remove);

my $samples_file = $ARGV[0] or die $usage;
my $num_parallel = $ARGV[1] or die $usage;

shift @ARGV;
shift @ARGV;


main: {

    my $star_fusion_prog = "$FindBin::Bin/../STAR-Fusion";
    
    # load the genome into memory:
    my $cmd = "$star_fusion_prog  --STAR_LoadAndExit";
    &process_cmd($cmd);


    # process samples individually

    my $cmds_file = basename($samples_file) . ".starF.cmds";
    open(my $ofh, ">$cmds_file") or die "Error, cannot write to $cmds_file";
    
    open(my $fh, $samples_file) or die "Error, cannot open file: $samples_file";
    while (<$fh>) {
        chomp;
        my ($sample_name, $left_fq, $right_fq) = split(/\t/);

        
        my $cmd = "$star_fusion_prog --STAR_use_shared_memory --left_fq $left_fq ";
        if ($right_fq) {
            $cmd .= " --right_fq $right_fq ";
        }
        $cmd .= " -O $sample_name.starF";

        $cmd .= " @ARGV ";
        
        print $ofh "$cmd\n";
        


    }
    close $fh;
    close $ofh;

    my $parafly_cmd = "ParaFly -c $cmds_file -CPU $num_parallel -vv -max_retry 1 ";
    &process_cmd($parafly_cmd);


    if ($do_remove) {
         
        # unload the genome from memory
        $cmd = "$star_fusion_prog  --STAR_Remove ";
        &process_cmd($cmd);
    }
    
    print STDERR "-done.\n\n";
    exit(0);
}
    
