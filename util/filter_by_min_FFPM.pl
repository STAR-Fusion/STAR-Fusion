#!/usr/bin/env perl

use strict;
use warnings;
use Carp;

use FindBin;
use lib("$FindBin::Bin/../PerlLib");
use DelimParser;

use Data::Dumper;

my $usage = "\n\n\tusage: $0 fusion_predictions.tsv  min_FFPM\n\n";

my $fusion_preds_file = $ARGV[0] or die $usage;
my $min_FFPM = $ARGV[1] or die $usage;


main: {

    open(my $fh, $fusion_preds_file) or confess "Error, cannot open file: $fusion_preds_file";

    my $tab_reader = new DelimParser::Reader($fh, "\t");
    my @colnames = $tab_reader->get_column_headers();


    my $pass_file = "$fusion_preds_file.minFFPM.$min_FFPM.pass";
    open(my $pass_ofh, ">$pass_file") or confess "Error, cannot write to $pass_file";
    my $pass_writer = new DelimParser::Writer($pass_ofh, "\t", [@colnames]);
    
    while(my $row = $tab_reader->get_row()) {

        my $ffpm = $row->{FFPM};
        if (! defined $ffpm) {
            confess "Error, no FFPM specified for row in file: $fusion_preds_file : " . Dumper($row);
        }
        if ($ffpm >= $min_FFPM) {
            $pass_writer->write_row($row);
        }
    }

    close($pass_ofh);

    exit(0);
}


        
