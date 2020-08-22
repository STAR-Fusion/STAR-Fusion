#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;

use lib "$FindBin::Bin/../PerlLib";
use SeqUtil;
use Fasta_reader;
use DelimParser;
use Nuc_translator;

my $usage = "usage: $0 fusion_prediction_summary.dat genome_lib_dir [half_length=50]\n\n";

my $fusion_dat_file = $ARGV[0] or die $usage;
my $genome_lib_dir = $ARGV[1] or die $usage;
my $half_length = $ARGV[2] || 50;


my $genome_fasta = "$genome_lib_dir/ref_genome.fa";

unless (-s $genome_fasta) {
    die "Error, cannot locate genome fasta file: $genome_fasta";
}

main : {

    
    open (my $fh, $fusion_dat_file) or die "Error, cannot open file: $fusion_dat_file";
    my $tab_reader = new DelimParser::Reader($fh, "\t");

    my @column_headers = $tab_reader->get_column_headers();

    push (@column_headers, "FusionSeq");

    my $tab_writer = new DelimParser::Writer(*STDOUT, "\t", \@column_headers);

    while (my $row = $tab_reader->get_row()) {
        
        my $break_left = $row->{LeftBreakpoint};
        my $break_right = $row->{RightBreakpoint};
        
        my $left_half_seq = &get_breakpoint_seq($break_left, 'left', $half_length);

        my $right_half_seq = &get_breakpoint_seq($break_right, 'right', $half_length);
        
        $row->{FusionSeq} = uc $left_half_seq . lc $right_half_seq;
        
        $tab_writer->write_row($row);
    }


    exit(0);
    

}

####
sub get_breakpoint_seq {
    my ($breakpoint_info, $side, $regionlength) = @_;
    
    unless ($side eq 'left' || $side eq 'right') { 
        die "Error, cannot parse side ($side) as 'left|right' ";
    }
    
    my ($chr, $coord, $orient) = split(/:/, $breakpoint_info);
    
    

    if ($orient) {

        # then has junction reads
        my $regionseq;

        
        if ($orient eq '+') {
            
            
            if ($side eq 'left') {
                $regionseq = &get_substr($chr, $coord - $regionlength, $regionlength);
            }
            elsif ($side eq 'right') {
                $regionseq = &get_substr($chr, $coord -1, $regionlength);
            }
        }
        
        elsif ($orient eq '-') {
                        
            if ($side eq 'left') {
                $regionseq = &get_substr($chr, $coord -1, $regionlength);
                $regionseq = &reverse_complement($regionseq);
            }
            elsif ($side eq 'right') {
                $regionseq = &get_substr($chr, $coord - $regionlength, $regionlength);
                $regionseq = &reverse_complement($regionseq);
            }
        }
        return($regionseq);
        
    }
    
    else {
        # no breakpoint reads
        return("NA");
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
