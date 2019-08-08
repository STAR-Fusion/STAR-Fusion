#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../../PerlLib");
use DelimParser;

my $usage = "\n\tusage: $0 fusion_predictions.tsv\n\n";

my $fusion_predictions_tsv = $ARGV[0] or die $usage;

main: {
    
    open(my $fh, $fusion_predictions_tsv) or die "Error, cannot open file: $fusion_predictions_tsv";
    my $delim_reader = new DelimParser::Reader($fh, "\t");

    while (my $row = $delim_reader->get_row()) {
        
        my $fusion_name = $delim_reader->get_row_val($row, "#FusionName");
        
        my $junction_reads = $delim_reader->get_row_val($row, "JunctionReads");
        &write_output($fusion_name, "J", $junction_reads);
        
        my $spanning_reads = $delim_reader->get_row_val($row, "SpanningFrags");
        &write_output($fusion_name, "S", $spanning_reads);


    }

    exit(0);
}


####
sub write_output {
    my ($fusion_name, $read_type, $reads) = @_;
    
    if ($reads eq ".") { return; }
    
    my @read_accs = split(/,/, $reads);

    foreach my $read_acc (@read_accs) {
        $read_acc =~ s/\/[12]$//;
        
        print join("\t", $fusion_name, $read_type, $read_acc) . "\n";
    }

    return;
}
        
