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



my $genome_fasta = "$genome_lib_dir/ref_genome.fa";

unless (-s $genome_fasta) {
    die "Error, cannot locate genome fasta file: $genome_fasta";
}

main : {

    
    open (my $fh, $fusion_dat_file) or die "Error, cannot open file: $fusion_dat_file";
    my $tab_reader = new DelimParser::Reader($fh, "\t");

    my @column_headers = $tab_reader->get_column_headers();

    push (@column_headers, "LeftBreakDinuc", "LeftBreakEntropy", "RightBreakDinuc", "RightBreakEntropy");

    my $tab_writer = new DelimParser::Writer(*STDOUT, "\t", \@column_headers);

    while (my $row = $tab_reader->get_row()) {
        
        my $break_left = $row->{LeftBreakpoint};
        my $break_right = $row->{RightBreakpoint};
        
        my ($left_splice, $left_entropy) = &examine_breakpoint_seq($break_left, 'left');

        my ($right_splice, $right_entropy) = &examine_breakpoint_seq($break_right, 'right');
        
        $row->{LeftBreakDinuc} = $left_splice;
        $row->{LeftBreakEntropy} = $left_entropy; 
        if ($left_entropy ne "NA") {
            $row->{LeftBreakEntropy} = sprintf("%.4f", $left_entropy) 
        }
        
        $row->{RightBreakDinuc} = $right_splice;
        $row->{RightBreakEntropy} = $right_entropy;
        if ($right_entropy ne "NA") {
            $row->{RightBreakEntropy} = sprintf("%.4f", $right_entropy);
        }
        
        $tab_writer->write_row($row);
    }


    exit(0);
    

}

####
sub examine_breakpoint_seq {
    my ($breakpoint_info, $side) = @_;

    unless ($side eq 'left' || $side eq 'right') { 
        die "Error, cannot parse side ($side) as 'left|right' ";
    }
    
    my ($chr, $coord, $orient) = split(/:/, $breakpoint_info);
    
    my ($dinuc, $anchor_seq);

    if ($orient) {

        # then has junction reads
        
        if ($orient eq '+') {
            
            my $subseq;
            if ($side eq 'left') {
                my $coord_start = $coord - $ANCHOR_SEQ_LENGTH + 1;
                
                $subseq = &get_substr($chr, $coord_start -1, $ANCHOR_SEQ_LENGTH + 2);
                $dinuc = substr($subseq, -2);
                $anchor_seq = substr($subseq, 0, $ANCHOR_SEQ_LENGTH);
                
            }
            elsif ($side eq 'right') {
                my $coord_start = $coord - 2;
                
                $subseq = &get_substr($chr, $coord_start -1, $ANCHOR_SEQ_LENGTH + 2);
                $dinuc = substr($subseq, 0, 2);
                $anchor_seq = substr($subseq, 2);
            }
            
            #print STDERR "+:$side:$subseq|$dinuc|$anchor_seq\n";
            
        }
        elsif ($orient eq '-') {
            
            my $subseq;
            
            if ($side eq 'left') {
                my $coord_start = $coord - 2;
                
                $subseq = &get_substr($chr, $coord_start -1, $ANCHOR_SEQ_LENGTH + 2);
                $dinuc = substr($subseq, 0, 2);
                $anchor_seq = substr($subseq, 2);
                
                
            }
            elsif ($side eq 'right') {
                my $coord_start = $coord - $ANCHOR_SEQ_LENGTH + 1;
                
                $subseq = &get_substr($chr, $coord_start -1, $ANCHOR_SEQ_LENGTH + 2);
                $dinuc = substr($subseq, -2);
                $anchor_seq = substr($subseq, 0, $ANCHOR_SEQ_LENGTH);
                
            }
            
            #print STDERR "-:$side:$subseq|$dinuc|$anchor_seq\n";
            
            $dinuc = &reverse_complement($dinuc);
            $anchor_seq = &reverse_complement($anchor_seq);
        }


        
        my $anchor_seq_entropy = &SeqUtil::compute_entropy($anchor_seq);
        
        
        return($dinuc, $anchor_seq_entropy);
        
    }
    
    else {
        # no breakpoint reads
        return("?", "NA");
    }
    
}


####
sub get_substr {
    my ($chr, $start_pos, $length) = @_;

    my $lend = $start_pos + 1;
    my $rend = $start_pos + $length;

    my $cmd = "samtools faidx $genome_fasta $chr:$lend-$rend";
    # print STDERR "CMD: $cmd\n";
    
    my $seq = `$cmd`;

    if ($?) {
        die "Error, command: $cmd died with ret $?";
    }
    
    chomp $seq;
    
    my @lines = split(/\n/, $seq);
    shift @lines; # remove header
    
    my $raw_seq = join("", @lines);

    return($raw_seq);
}
