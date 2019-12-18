#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../../PerlLib");
use DelimParser;
use File::Basename;

my $usage = "\n\tusage: $0 A.fusions.aggregated.tsv  B.fusions.aggregated.tsv\n\n";

my $A_tsv = $ARGV[0] or die $usage;
my $B_tsv = $ARGV[1] or die $usage;

main: {

    my %fusions_A = &parse_top_fusions($A_tsv);

    my %fusions_B = &parse_top_fusions($B_tsv);

    my %all_fusion_calls = map { + $_ => 1 } (keys %fusions_A, keys %fusions_B);

    my @fusions = sort keys %all_fusion_calls;

    print "Fusion\t" . basename($A_tsv) . "\t" . basename($B_tsv) . "\n"; # header line
    foreach my $fusion (@fusions) {
        my $A_ffpm = $fusions_A{$fusion} || 0;
        my $B_ffpm = $fusions_B{$fusion} || 0;

        print join("\t", $fusion, $A_ffpm, $B_ffpm) . "\n";
    }

    exit(0);
    
}


####
sub parse_top_fusions {
    my ($tsv_file) = @_;

    my $fh;
    if ($tsv_file =~ /\.gz$/) {
        open($fh, "gunzip -c $tsv_file | ") or die "Error, cannot gunzip file: $tsv_file";
    }
    else {
        open($fh, $tsv_file) or die "Error, cannot open file: $tsv_file";
    }
    
    my $delim_reader = new DelimParser::Reader($fh, "\t");
    
    my %top_fusions;

    while (my $row = $delim_reader->get_row()) {
        
        my $sample_name = $delim_reader->get_row_val($row, "#sample");
        my $fusion_name = $delim_reader->get_row_val($row, "#FusionName");
        my $FFPM = $delim_reader->get_row_val($row, "FFPM");
        
        $sample_name =~ s/\.(Fusion|STAR).*$//g; # just the sample please

        my $left_breakpoint = $delim_reader->get_row_val($row, "LeftBreakpoint");
        my $right_breakpoint = $delim_reader->get_row_val($row, "RightBreakpoint");
        
        $fusion_name = join("::", $sample_name, $fusion_name, $left_breakpoint, $right_breakpoint);
        
        if ( (! exists $top_fusions{$fusion_name})
             ||
             $top_fusions{$fusion_name} < $FFPM) {
            
            $top_fusions{$fusion_name} = $FFPM;
        }
        
    }
    
    return(%top_fusions);
    
}
