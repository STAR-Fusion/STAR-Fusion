#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use DelimParser;


my $usage = "\n\n\tusage: $0 fusion_preds.tsv\n\n\t\t(writes .brkptselect.pass and .brkptselect.filtered files)\n\n\n";

my $fusion_preds_file = $ARGV[0] or die $usage;

main: {
    
    open(my $fh, $fusion_preds_file) or die "Error, cannot open file: $fusion_preds_file";
    my $delim_reader = new DelimParser::Reader($fh, "\t");

    my @column_headers = $delim_reader->get_column_headers();

    my $pass_file = "$fusion_preds_file.brkptselect.pass";
    open(my $pass_ofh, ">$pass_file") or die "Error, cannot write to $pass_file";
    my $pass_writer = new DelimParser::Writer($pass_ofh, "\t", \@column_headers);
    
    
    my $filtered_file = "$fusion_preds_file.brkptselect.filtered";
    open(my $filtered_ofh, ">$filtered_file") or die "Error, cannot write to $filtered_file";
    my $filtered_writer = new DelimParser::Writer($filtered_ofh, "\t", \@column_headers);

    my $pass_counter = 0;
    my $filtered_counter = 0;


    my %breakpoint_to_fusions;
    
    while (my $row = $delim_reader->get_row()) {

        my $left_breakpoint = $delim_reader->get_row_val($row, "LeftBreakpoint");
        my $right_breakpoint = $delim_reader->get_row_val($row, "RightBreakpoint");
        
        my $breakpoint_token = join("$;", $left_breakpoint, $right_breakpoint);

        my $J = $delim_reader->get_row_val($row, "JunctionReadCount");
        my $S = $delim_reader->get_row_val($row, "SpanningFragCount");

        my $incl_ref_annot_splice = $delim_reader->get_row_val($row, "SpliceType");
        
        my $score = $J + $S;

        if ($incl_ref_annot_splice eq "ONLY_REF_SPLICE") {
            # give small boost to offset ties where it doesnt match w/ ref splice of annot.
            $score += 1;
        }
        
        
        push (@{$breakpoint_to_fusions{$breakpoint_token}}, { row => $row,
                                                              score => $score } );
    }

    my @pass_entries;
    my @fail_entries;

    foreach my $breakpoint (keys %breakpoint_to_fusions) {
        my @entries = @{$breakpoint_to_fusions{$breakpoint}};
        @entries = reverse sort {$a->{score} <=> $b->{score}} @entries;

        my $best_entry = shift @entries;
        push (@pass_entries, $best_entry);

        if (@entries) {
            push (@fail_entries, @entries);
        }
    }

    ## report pass entries
    @pass_entries = reverse sort {$a->{score}<=>$b->{score}} @pass_entries;
    foreach my $pass_entry (@pass_entries) {
        $pass_writer->write_row($pass_entry->{row});
        $pass_counter++;
    }
    
    if (@fail_entries) {
        @fail_entries = reverse sort {$a->{score}<=>$b->{score}} @fail_entries;

        foreach my $fail_entry (@fail_entries) {
            $filtered_writer->write_row($fail_entry->{row});
            $filtered_counter++;
        }
    }
    
    print STDERR "-filter_lesser_candidates_at_breakpoint: (pass: $pass_counter, filtered: $filtered_counter)\n";
    
    exit(0);
}

