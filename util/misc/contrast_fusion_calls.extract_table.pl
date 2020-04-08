#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../../PerlLib");
use DelimParser;
use File::Basename;

use Getopt::Long qw(:config posix_default no_ignore_case bundling pass_through);

my $usage = <<__EOUSAGE__;

########################################################################################
#
# --A_fusions <string>      aggregated fusions dat file A
#
# --B_fusions <string>      aggregated fusions dat file B
#
# --val_type <string>       FFPM  | J | S | T   (J=junction, S=split, and T=total reads)
#
########################################################################################


__EOUSAGE__

    ;


my $help_flag;
my $A_tsv;
my $B_tsv;
my $val_type;


&GetOptions (
    'h' => \$help_flag,
    'A_fusions=s' => \$A_tsv,
    'B_fusions=s' => \$B_tsv,
    'val_type=s' => \$val_type,
    
    );

unless ($A_tsv && $B_tsv && $val_type) {
    die $usage;
}

unless ($val_type =~ /^(FFPM|J|S|T)$/) {
    die "error, val_type $val_type not supported";
}


main: {

    my %fusions_A = &parse_top_fusions($A_tsv, $val_type);

    my %fusions_B = &parse_top_fusions($B_tsv, $val_type);

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
    my ($tsv_file, $val_type) = @_;
    
    my $fh;
    if ($tsv_file =~ /\.gz$/) {
        open($fh, "gunzip -c $tsv_file | ") or die "Error, cannot gunzip file: $tsv_file";
    }
    else {
        open($fh, $tsv_file) or die "Error, cannot open file: $tsv_file";
    }
    
    my $delim_reader = new DelimParser::Reader($fh, "\t");
    
    my %fusion_to_val;

    while (my $row = $delim_reader->get_row()) {
        
        my $sample_name = $delim_reader->get_row_val($row, "#sample");
        my $fusion_name = $delim_reader->get_row_val($row, "#FusionName");
        my $FFPM = "NA";
        if ($val_type eq "FFPM") {
            # not included in fusion inspector 'inspect' mode.
            $FFPM = $delim_reader->get_row_val($row, "FFPM");
        }
        my $J = $delim_reader->get_row_val($row, "JunctionReadCount");
        my $S = $delim_reader->get_row_val($row, "SpanningFragCount");
        my $T = $J + $S;
        
        $sample_name =~ s/\.(Fusion|STAR).*$//g; # just the sample please

        my $left_breakpoint = $delim_reader->get_row_val($row, "LeftBreakpoint");
        my $right_breakpoint = $delim_reader->get_row_val($row, "RightBreakpoint");

        ## encoding sample name and breakpoint info into a unique fusion instance.
        $fusion_name = join("::", $sample_name, $fusion_name, $left_breakpoint, $right_breakpoint);

        my $val =
            ($val_type eq "FFPM") ? $FFPM :
            ($val_type eq "J") ? $J :
            ($val_type eq "S") ? $S :
            ($val_type eq "T") ? $T :
            die "Error, not recognizing val type: $val_type";
        
        
        if (exists $fusion_to_val{$fusion_name}) {
            die "Error, found multiple instances of fusion: $fusion_name ";
        }
        
        $fusion_to_val{$fusion_name} = $val;
        
    }
    
    return(%fusion_to_val);
    
}

