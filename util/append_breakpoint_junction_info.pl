#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;

use lib "$FindBin::Bin/../PerlLib";
use SeqUtil;
use Fasta_reader;
use DelimParser;
use Nuc_translator;

my $usage = "usage: $0 fusion_prediction_summary.dat genome_lib_dir\n\n";

my $fusion_dat_file = $ARGV[0] or die $usage;
my $genome_lib_dir = $ARGV[1] or die $usage;

my $ANCHOR_SEQ_LENGTH = 15;

main : {

    my $genome_fasta = "$genome_lib_dir/ref_genome.fa";
    unless (-s $genome_fasta) {
        die "Error, cannot locate genome fasta file: $genome_fasta";
    }
    
    open (my $fh, $fusion_dat_file) or die $!;
    my $tab_reader = new DelimParser::Reader($fh, "\t");

    my @column_headers = $tab_reader->get_column_headers();

    push (@column_headers, "LeftBreakDinuc", "LeftBreakEntropy", "RightBreakDinuc", "RightBreakEntropy");

    my $tab_writer = new DelimParser::Writer(*STDOUT, "\t", \@column_headers);


    my $fasta_reader = new Fasta_reader($genome_fasta);
    
    my %seqs = $fasta_reader->retrieve_all_seqs_hash();


    while (my $row = $tab_reader->get_row()) {
        
        my $break_left = $row->{LeftBreakpoint};
        my $break_right = $row->{RightBreakpoint};
        
        my ($left_splice, $left_entropy) = &examine_breakpoint_seq($break_left, \%seqs, 'left');

        my ($right_splice, $right_entropy) = &examine_breakpoint_seq($break_right, \%seqs, 'right');
        
        $row->{LeftBreakDinuc} = $left_splice;
        $row->{LeftBreakEntropy} = $left_entropy;

        $row->{RightBreakDinuc} = $right_splice;
        $row->{RightBreakEntropy} = $right_entropy;
        
        $tab_writer->write_row($row);
    }


    exit(0);
    

}

####
sub examine_breakpoint_seq {
    my ($breakpoint_info, $seqs_href, $side) = @_;

    unless ($side eq 'left' || $side eq 'right') { 
        die "Error, cannot parse side ($side) as 'left|right' ";
    }
    
    my ($chr, $coord, $orient) = split(/:/, $breakpoint_info);
    
    my ($dinuc, $anchor_seq);

    if ($orient eq '+') {
 
        my $subseq;
        if ($side eq 'left') {
            my $coord_start = $coord - $ANCHOR_SEQ_LENGTH + 1;
            
            $subseq = substr($seqs_href->{$chr}, $coord_start -1, $ANCHOR_SEQ_LENGTH + 2);
            $dinuc = substr($subseq, -2);
            $anchor_seq = substr($subseq, 0, $ANCHOR_SEQ_LENGTH);

        }
        elsif ($side eq 'right') {
            my $coord_start = $coord - 2;
            
            $subseq = substr($seqs_href->{$chr}, $coord_start -1, $ANCHOR_SEQ_LENGTH + 2);
            $dinuc = substr($subseq, 0, 2);
            $anchor_seq = substr($subseq, 2);
        }
        
        print STDERR "+:$side:$subseq|$dinuc|$anchor_seq\n";
        
    }
    else {
        # (-) orient
        
        my $subseq;

        if ($side eq 'left') {
            my $coord_start = $coord - 2;
            
            $subseq = substr($seqs_href->{$chr}, $coord_start -1, $ANCHOR_SEQ_LENGTH + 2);
            $dinuc = substr($subseq, 0, 2);
            $anchor_seq = substr($subseq, 2);

            
        }
        elsif ($side eq 'right') {
            my $coord_start = $coord - $ANCHOR_SEQ_LENGTH + 1;
            
            $subseq = substr($seqs_href->{$chr}, $coord_start -1, $ANCHOR_SEQ_LENGTH + 2);
            $dinuc = substr($subseq, -2);
            $anchor_seq = substr($subseq, 0, $ANCHOR_SEQ_LENGTH);



        }

        print STDERR "-:$side:$subseq|$dinuc|$anchor_seq\n";

        $dinuc = &reverse_complement($dinuc);
        $anchor_seq = &reverse_complement($anchor_seq);
    }

    
    my $anchor_seq_entropy = &SeqUtil::compute_entropy($anchor_seq);
    

    return($dinuc, $anchor_seq_entropy);
}
