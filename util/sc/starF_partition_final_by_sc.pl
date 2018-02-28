#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../../PerlLib");
use DelimParser;
use Data::Dumper;

my $usage = "\n\tusage: $0 star-fusion.fusion_predictions.tsv\n\n";

my $file = $ARGV[0] or die $usage;

main: {

    open(my $fh, $file) or die "Error, cannot open file: $file\n";
    my $delim_parser = new DelimParser::Reader($fh, "\t");

    my @column_headers = $delim_parser->get_column_headers();

    my @out_col_headers = @column_headers;

    @out_col_headers = ($out_col_headers[0], 'Cell', @out_col_headers[1..$#out_col_headers]);
    
    my $delim_writer = new DelimParser::Writer(*STDOUT, "\t", \@out_col_headers);

    while(my $row = $delim_parser->get_row()) {

        my %cellrow = %$row; # shallow copy
        
        my $JunctionReads = $delim_parser->get_row_val($row, 'JunctionReads');
        my $SpanningFrags = $delim_parser->get_row_val($row, 'SpanningFrags');
                
        
        my %cell_to_JunctionReads = &partition_by_cell($JunctionReads);
        my %cell_to_SpanningFrags = &partition_by_cell($SpanningFrags);
        
        foreach my $cell (&unique(keys %cell_to_JunctionReads,
                                  keys %cell_to_SpanningFrags,
                          )) {
            
            my ($cell_junction_reads_count, 
                $cell_junction_reads_string) = &capture_cell_read_info($cell, \%cell_to_JunctionReads);
            
            my ($cell_spanning_frags_count, 
                $cell_spanning_frags_string) = &capture_cell_read_info($cell, \%cell_to_SpanningFrags);
            
            # generate single cell result:
            $cellrow{Cell} = $cell;
            
            $cellrow{JunctionReadCount} = $cell_junction_reads_count;
            $cellrow{JunctionReads} = $cell_junction_reads_string;
            
            $cellrow{SpanningFragCount} = $cell_spanning_frags_count;
            $cellrow{SpanningFrags} = $cell_spanning_frags_string;
            
            $delim_writer->write_row(\%cellrow);
            
        }
        
    }

    
    exit(0);
}


####
sub partition_by_cell {
    my ($reads_string) = @_;

    #print "Reads string: [$reads_string]\n";
    
    my %cell_to_reads;

    if ($reads_string eq '.') {
        return(%cell_to_reads);
    }
    
    my @reads = split(/,/, $reads_string);

    foreach my $read (@reads) {
        my ($cell, $rest) = split(/\^/, $read);
        $cell_to_reads{$cell}->{$read} = 1;
    }

    return(%cell_to_reads);
}

####
sub unique {
    my (@vals) = @_;

    my %mappings = map { + $_ => 1 } @vals;

    return(keys %mappings);
}

####
sub capture_cell_read_info {
    my ($cell, $mappings_href) = @_;

    my $read_count = 0;
    my $read_string = ".";

    if (exists $mappings_href->{$cell}) {

        my @reads = keys %{$mappings_href->{$cell}};

        $read_string = join(",", @reads);

        $read_count = scalar(@reads);
    }

    #print STDERR "cell: $cell, mappings_href = " . Dumper($mappings_href) . " =>  ($read_count, $read_string)\n\n";
    
    
    return($read_count, $read_string);
}


