#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use DelimParser;

my $usage = "\n\n\tusage: $0 finspector.fusion_predictions.final.abridged num_total_rnaseq_frags\n\n";

my $finspector_results = $ARGV[0] or die $usage;
my $num_frags = $ARGV[1] or die $usage;

main: {

    open (my $fh, $finspector_results) or die "Error, cannot open file $finspector_results";
    my $tab_reader = new DelimParser::Reader($fh, "\t");

    my @column_headers = $tab_reader->get_column_headers();
    push (@column_headers, "FFPM");

    my $tab_writer = new DelimParser::Writer(*STDOUT, "\t", \@column_headers);
    
    while (my $row = $tab_reader->get_row()) {
        
        my $J = $row->{JunctionReadCount};
        my $S = $row->{SpanningFragCount};
        
        my $J_FFPM = &compute_FFPM($J, $num_frags);
        my $S_FFPM = &compute_FFPM($S, $num_frags);

        $row->{FFPM} = $J_FFPM + $S_FFPM;
        
        $tab_writer->write_row($row);
    }
    close $fh;
    
    exit(0);
    
}


####
sub compute_FFPM {
    my ($count_frags, $total_frags) = @_;

    my $ffpm = $count_frags / $total_frags * 1e6;

    $ffpm = sprintf("%.4f", $ffpm);
    
    return($ffpm);
}

