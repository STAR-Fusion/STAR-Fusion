#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "\n\n\tusage: $0 left.fq fusions.final.abridged\n\n";

my $fq_file = $ARGV[0] or die $usage;
my $fusions_file = $ARGV[1] or die $usage;


main: {

    my $num_frags = &get_num_frags($fq_file);


    open (my $fh, $fusions_file) or die "$!";
    my $header = <$fh>;
    my @header_pts = split(/\t/, $header);
    $header = join("\t", @header_pts[0..2], "J_FFPM", "S_FFPM", @header_pts[3..$#header_pts]);
    print $header;

    while (<$fh>) {
        my @x = split(/\t/);
        my $J = $x[1];
        my $S = $x[2];

        my $J_FFPM = sprintf("%.4f", $J/$num_frags * 1e6);
        my $S_FFPM = sprintf("%.4f", $S/$num_frags * 1e6);

        print join("\t", @x[0..2], $J_FFPM, $S_FFPM, @x[3..$#x]);
    }
    close $fh;
    
    exit(0);
}

####
sub get_num_frags {
    my ($fq_filename) = @_;

    my $cmd;
    if ($fq_filename =~ /\.gz/) {
        $cmd = "zcat $fq_filename | wc -l";
    }
    else {
        $cmd = "cat $fq_filename | wc -l";
    }

    my $linecount = `$cmd`;
    chomp $linecount;
    unless ($linecount =~ /\d/) {
        die "Error, cannot determine linecount of file via: \"$cmd\", result: $linecount ";
    }
    
    my $num_frags = $linecount / 4;
    
    return($num_frags);
}


