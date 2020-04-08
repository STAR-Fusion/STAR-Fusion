package ChimericCigarParser;

use strict;
use warnings;
use Carp;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(get_genome_coords_via_cigar);

####
sub get_genome_coords_via_cigar {
    my ($rst, $cigar) = @_;

    ## borrowing this code from my SAM_entry.pm

    
    my $genome_lend = $rst;

    my $alignment = $cigar;

    my $query_lend = 0;

    my @genome_coords;
    my @query_coords;


    $genome_lend--; # move pointer just before first position.
    
    while ($alignment =~ /(\d+)([A-Zp])/g) {
        my $len = $1;
        my $code = $2;
        
        unless ($code =~ /^[MSDNIHp]$/) {
            confess "Error, cannot parse cigar code [$code] ";
        }
        
        # print "parsed $len,$code\n";
        
        if ($code eq 'M') { # aligned bases match or mismatch
            
            my $genome_rend = $genome_lend + $len;
            my $query_rend = $query_lend + $len;
            
            push (@genome_coords, [$genome_lend+1, $genome_rend]);
            push (@query_coords, [$query_lend+1, $query_rend]);
            
            # reset coord pointers
            $genome_lend = $genome_rend;
            $query_lend = $query_rend;
            
        }
        elsif ($code eq 'D' || $code eq 'N' || $code eq 'p') { # insertion in the genome or gap in query (intron, perhaps)
            $genome_lend += $len;
            
        }
        
        elsif ($code eq 'I'  # gap in genome or insertion in query 
               ||
               $code eq 'S' || $code eq 'H')  # masked region of query
        { 
            $query_lend += $len;
            
        }
    }
    
    return(\@genome_coords, \@query_coords);
}

1; #EOM
