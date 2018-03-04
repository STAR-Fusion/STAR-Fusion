#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use FindBin;
use lib ("$FindBin::Bin/../../PerlLib");
use Pipeliner;

my $usage = "usage: $0 aligned.bam [already_uBam]\n\n";

my $abam_file = $ARGV[0] or die $usage;
my $already_ubam = $ARGV[1];

my $PICARD_HOME = $ENV{PICARD_HOME} or die "Error, must have PICARD_HOME env var set to where picard.jar is installed";

my $checkpoint_dir = "$abam_file.__checkpoints";
unless (-d $checkpoint_dir) {
    mkdir $checkpoint_dir or die "Error, cannot mkdir $checkpoint_dir";
}

my $tmpdir = "$checkpoint_dir/TMP";
if (! -d $tmpdir) {
    mkdir $tmpdir or die "Error, cannot mkdir $tmpdir";
}


main: {

    my $pipeliner = new Pipeliner(-verbose=> 2,
                                  -checkpoint_dir => $checkpoint_dir);

    my $sample_name = basename($abam_file);
    $sample_name =~ s/\.bam$//;

    my $ubam;
    if ($already_ubam) {
        $ubam = $abam_file;
    }
    else {
    
        $ubam = $abam_file;
        $ubam =~ s/\.bam$/\.reverted.bam/ or die "Error, cannot update name of bam file to included reverted: $ubam";
                
        # revert abam to ubam file
        my $cmd = "java -jar $PICARD_HOME/picard.jar RevertSam I=$abam_file O=$ubam SO=queryname REMOVE_ALIGNMENT_INFORMATION=true TMP_DIR=$tmpdir";
        $pipeliner->add_commands(new Command($cmd, "$sample_name.reverted.ok"));
        
    }
    
    # convert to fastq
    my $cmd = "java -jar $PICARD_HOME/picard.jar SamToFastq I=$ubam VALIDATION_STRINGENCY=LENIENT FASTQ=${sample_name}_1.fastq SECOND_END_FASTQ=${sample_name}_2.fastq";
    $pipeliner->add_commands(new Command($cmd, "$sample_name.fq_out.ok"));

    # gzip fastq files
    $cmd = "gzip ${sample_name}_1.fastq ${sample_name}_2.fastq";
    $pipeliner->add_commands(new Command($cmd, "$sample_name.gzipped_fq.ok"));

    $pipeliner->run();


    exit(0);
}
