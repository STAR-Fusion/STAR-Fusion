#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../../PerlLib");
use DelimParser;
use List::MoreUtils qw(uniq);

my $usage = "\n\n\tusage: $0 STAR-F.results  FI.results\n\n";

my $starF_file = $ARGV[0] or die $usage;
my $FI_file = $ARGV[1] or die $usage;

main: {

    my %starF_reads_to_fusions = &parse_fusion_reads($starF_file);

    my %FI_reads_to_fusions = &parse_fusion_reads($FI_file);
    

    print "#frag\tstarF\tFI\n";

    my %all_frags = map { + $_ => 1 } (keys %starF_reads_to_fusions, keys %FI_reads_to_fusions);

    foreach my $frag (sort keys %all_frags) {
        my @starF_fusions;
        if (exists $starF_reads_to_fusions{$frag}) {
            @starF_fusions = uniq @{$starF_reads_to_fusions{$frag}};
        }
        else {
            @starF_fusions = (".");
        }

        my @FI_fusions;
        if (exists $FI_reads_to_fusions{$frag}) {
            @FI_fusions = uniq @{$FI_reads_to_fusions{$frag}};
        }
        else {
            @FI_fusions = (".");
        }

        print join("\t", $frag, join(",", sort @starF_fusions), join(",", sort @FI_fusions) ) . "\n";
    
    }

    exit(0);
}

####
sub parse_fusion_reads {
    my ($file) = @_;

    my %reads_to_fusions;
    
    open(my $fh, $file) or die $!;
    my $delim_parser = new DelimParser::Reader($fh, "\t");

    while(my $row = $delim_parser->get_row()) {

        my $fusion = $row->{'#FusionName'};
        
        my $J_reads = $row->{JunctionReads};
        
        foreach my $read (split(/,/, $J_reads)) {
            $read =~ s/\/[12]$//;
            push (@{$reads_to_fusions{$read}}, "$fusion|J") if $read ne ".";
        }

        my $S_reads = $row->{SpanningFrags};

        foreach my $read (split(/,/, $S_reads)) {
            push (@{$reads_to_fusions{$read}}, "$fusion|S") if $read ne ".";
        }

    }


    return(%reads_to_fusions);
}
