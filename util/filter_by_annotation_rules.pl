#!/usr/bin/env perl

use strict;
use warnings;

use Carp;
use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use DelimParser;


my $usage = "usage: $0 CTAT.fusion_predictions.tsv ctat_genome_lib_dir\n\n";

my $predictions_file = $ARGV[0] or die $usage;
my $genome_lib_dir = $ARGV[1] or die $usage;

main: {
    
    my $annot_filt_module = "$genome_lib_dir/AnnotFilterRule.pm";
    unless (-s $annot_filt_module) {
        die "Error, cannot locate required $annot_filt_module  ... be sure to use a more modern version of the companion CTAT_GENOME_LIB ";
    }

    require $annot_filt_module;

    open(my $fh, $predictions_file) or die "Error, cannot open file: $predictions_file ";
    
    my $delim_parser = new DelimParser::Reader($fh, "\t");

    my $pass_file = "$predictions_file.pass";
    open(my $ofh_pass, ">$pass_file") or die "Error, cannot write to file: $pass_file";

    
    my $fail_file = "$predictions_file.annot_filt";
    open(my $ofh_fail, ">$fail_file") or die "Error, cannot write to file: $fail_file";

    my @column_headers = $delim_parser->get_column_headers();

    my $pass_writer = new DelimParser::Writer($ofh_pass, "\t", \@column_headers);
    
    my $fail_reason_header = 'Annot_Fail_Reason';
    my $fail_writer = new DelimParser::Writer($ofh_fail, "\t", [@column_headers, $fail_reason_header]);


    while(my $pred = $delim_parser->get_row()) {

        if (my $filter_reason = &AnnotFilterRule::examine_fusion_prediction($pred)) {
            $pred->{$fail_reason_header} = $filter_reason;
            $fail_writer->write_row($pred);
        }
        else {
            # all good
            $pass_writer->write_row($pred);
        }
    }


    close $ofh_pass;
    close $ofh_fail;

    exit(0);
}


