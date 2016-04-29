#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use DelimParser;

my $usage = "\n\tusage: $0 inputFile.tab comma-delim-headers-exclude\n\n";

my $input_file = $ARGV[0] or die $usage;
my $comma_delim_headers = $ARGV[1] or die $usage;

main: {

    my %headers_exclude = map { $_ => 1 } split(/,/, $comma_delim_headers);
        
    open (my $fh, $input_file) or die "Error, cannot open file $input_file";

    my $tab_reader = new DelimParser::Reader($fh, "\t");

    my @column_headers = $tab_reader->get_column_headers();

    my @column_headers_want;
    foreach my $header (@column_headers) {
        unless ($headers_exclude{$header}) {
            push (@column_headers_want, $header);
        }
    }
    
    my $tab_writer = new DelimParser::Writer(*STDOUT, "\t", \@column_headers_want);
    
    while (my $row = $tab_reader->get_row()) {
        $tab_writer->write_row($row);
    }

    exit(0);
}


    
