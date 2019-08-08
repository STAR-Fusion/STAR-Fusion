#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use DelimParser;


my $usage = "\n\n\tusage: $0 fusion_preds.tsv\n\n\t\t(writes .pass and .filtered files)\n\n\n";

my $fusion_preds_file = $ARGV[0] or die $usage;

main: {

    open(my $fh, $fusion_preds_file) or die "Error, cannot open file: $fusion_preds_file";
    my $delim_reader = new DelimParser::Reader($fh, "\t");

    my @column_headers = $delim_reader->get_column_headers();

    my $pass_file = "$fusion_preds_file.pass";
    open(my $pass_ofh, ">$pass_file") or die "Error, cannot write to $pass_file";
    my $pass_writer = new DelimParser::Writer($pass_ofh, "\t", \@column_headers);
    
    
    my $filtered_file = "$fusion_preds_file.filtered";
    open(my $filtered_ofh, ">$filtered_file") or die "Error, cannot write to $filtered_file";
    my $filtered_writer = new DelimParser::Writer($filtered_ofh, "\t", \@column_headers);

    my $pass_counter = 0;
    my $filtered_counter = 0;
    
    while (my $row = $delim_reader->get_row()) {

        my $left_dinuc = $delim_reader->get_row_val($row, "LeftBreakDinuc");
        my $right_dinuc = $delim_reader->get_row_val($row, "RightBreakDinuc");

        my $fusion_name = $delim_reader->get_row_val($row, "#FusionName");
        
        my $combo = $left_dinuc . $right_dinuc;

        my $pass_flag = 0;
        
        if ($combo =~ /^(GTAG|GCAG|ATAC)$/
                ||
            ## allow for known cases of peculiar fusions.
            $fusion_name =~ /\@/ # includes the IGH and IGL super loci

            ## TODO:  add additional exceptions
            
            ) {

            $pass_flag = 1;
            
        }
        

        if ($pass_flag) {
        
            $pass_writer->write_row($row);
            $pass_counter++;
        }
        else {
            $filtered_writer->write_row($row);
            $filtered_counter++;
        }
        
    }

    print STDERR "-filter_likely_RT_artifacts: (pass: $pass_counter, filtered: $filtered_counter)\n";
    
    exit(0);
}

