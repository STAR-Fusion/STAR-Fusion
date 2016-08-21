#!/usr/bin/env perl

package SeqUtil;
use strict;
use warnings;


####
sub compute_entropy {
    my ($sequence) = @_;

    my @chars = split(//, $sequence);
    my %char_counter;

    foreach my $char (@chars) {
        $char_counter{$char}++;
    }
    
    my $num_chars = scalar(@chars);

    my $entropy = 0;
    foreach my $char (keys %char_counter) {
        my $count = $char_counter{$char};
        my $p = $count / $num_chars;

        $entropy += $p * (  log(1/$p) / log(2) );
    }

    return($entropy);
}

1; #EOM
