#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use FindBin;
use lib ("$FindBin::Bin/../lib");
use Fasta_reader;
use Getopt::Long qw(:config posix_default no_ignore_case bundling pass_through);                                                 
use TiedHash;



my $cdna_fasta_file = "$FindBin::Bin/../resources/gencode.v19.annotation.gtf.exons.cdna.gz";


my $usage = <<__EOUSAGE__;

###################################################################################################
#
# Required:
#
#  --fusion_preds <string>        "geneA--geneB"
#
# Optional: 
#
#  --ref_cdna <string>            reference cDNA sequences fasta file (generated specially based on gtf -see docs) 
#                                 (default: $cdna_fasta_file)
#
#  --blast_opts <string>          any blast options ie. ("-outfmt 6 -evalue 1e-3 -max_target_seqs 1 -lcase_masking ....")
#
#
####################################################################################################


__EOUSAGE__

    ;

my $help_flag;

my $fusion_preds;
my $BLAST_OPTS = "";

&GetOptions ( 'h' => \$help_flag, 
              
              'fusion_preds=s' => \$fusion_preds,
              'ref_cdna=s' => \$cdna_fasta_file,
              
              'blast_opts=s' => \$BLAST_OPTS,              
    );

if (@ARGV) {
    die "Error, dont recognize arguments: @ARGV";
}


if ($help_flag) {
    die $usage;
}

unless ($fusion_preds && $cdna_fasta_file) {
    die $usage;
}


my $ref_cdna_idx_file = "$cdna_fasta_file.idx";
unless (-s $ref_cdna_idx_file) {
    die "Error, cannot find indexed fasta file: $cdna_fasta_file.idx; be sure to build an index - see docs.\n";
}


my $CDNA_IDX = new TiedHash({ use => $ref_cdna_idx_file });

main: {

    my ($geneA, $geneB) = split(/--/, $fusion_preds);

    &examine_seq_similarity($geneA, $geneB);
    
    exit(0);
}


####
sub examine_seq_similarity {
    my ($geneA, $geneB) = @_;
    
    my $fileA = "tmp.gA.fa";
    my $fileB = "tmp.gB.fa";
    
    {
        # write file A
        open (my $ofh, ">$fileA") or die "Error, cannot write to $fileA";
        my $cdna_seqs = $CDNA_IDX->get_value($geneA) or confess "Error, no sequences found for gene: $geneA";
        print $ofh $cdna_seqs;
        close $ofh;
    }
        
    
    {
        # write file B
        open (my $ofh, ">$fileB") or die "Error, cannot write to file $fileB";
        my $cdna_seqs = $CDNA_IDX->get_value($geneB) or confess "Error, no sequences found for gene: $geneB";
        print $ofh $cdna_seqs;
        close $ofh;
    }
    
    ## blast them:
    my $cmd = "makeblastdb -in $fileB -dbtype nucl 2>/dev/null 1>&2";
    &process_cmd($cmd);
    
    $cmd = "blastn -db $fileB -query $fileA $BLAST_OPTS ";
    &process_cmd($cmd);
    
    return;
}



####
sub process_cmd {
    my ($cmd) = @_;

    print STDERR "CMD: $cmd\n";
        
    my $ret = system($cmd);
    if ($ret) {

        die "Error, cmd $cmd died with ret $ret";
    }
    
    return;
}
    
