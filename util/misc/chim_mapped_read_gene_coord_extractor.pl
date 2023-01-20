#!/usr/bin/env perl

# contributed by Brian Haas, Broad Institute, 2015

use strict;
use warnings;
use Carp;
use Cwd;
use FindBin;
use JSON::XS;
use lib ($ENV{EUK_MODULES});
use ChimericCigarParser;
use Data::Dumper;

## Options

my $usage = "\n\n\tusage: $0 chimJ_file.mapepd2genes\n\n";

my $chimeric_junction_file = $ARGV[0] or die $usage;
my $help_flag;


my $JSON_DECODER = JSON::XS->new();

open(my $fh, $chimeric_junction_file) or die "Error, cannot open file: $chimeric_junction_file";



main: {
    
    print STDERR "-parsing $chimeric_junction_file, organizing read mapping info.\n";

    while (<$fh>) {
        if (/^\#/) { next; } 
        my $line = $_;
    
    # if parts i,j of a chimeric read effectively match the same gene
    # then we discard that read.
    

    # from star doc:
    #The rst 9 columns give information about the chimeric junction:

    #The format of this le is as follows. Every line contains one chimerically aligned read, e.g.:
    #chr22 23632601 + chr9 133729450 + 1 0 0 SINATRA-0006:3:3:6387:56650 23632554 47M29S 133729451 47S29M40p76M
    #The first 9 columns give information about the chimeric junction:

    #column 1: chromosome of the donor
    #column 2: rst base of the intron of the donor (1-based)
    #column 3: strand of the donor
    #column 4: chromosome of the acceptor
    #column 5: rst base of the intron of the acceptor (1-based)
    #column 6: strand of the acceptor
    #column 7: junction type: -1=encompassing junction (between the mates), 1=GT/AG, 2=CT/AC
    #column 8: repeat length to the left of the junction
    #column 9: repeat length to the right of the junction
    #Columns 10-14 describe the alignments of the two chimeric segments, it is SAM like. Alignments are given with respect to the (+) strand
    #column 10: read name
    #column 11: rst base of the rst segment (on the + strand)
    #column 12: CIGAR of the rst segment
    #column 13: rst base of the second segment
    #column 14: CIGAR of the second segment
    
        
        chomp $line;
        my @x = split(/\t/, $line);
        
        my $json_left = $x[$#x-1];
        my $json_right = $x[$#x];
        
        if ($json_left eq '.' || $json_right eq '.') {
            next;
        }

        my $chrom_left = $x[0];
        my $chrom_right = $x[3];

        my $strand_left = $x[2];
        my $strand_right = $x[5];
        
        my ($left_genes_aref, $right_genes_aref);
        
        eval {
            $left_genes_aref = $JSON_DECODER->decode($json_left);
        };
        if ($@) {
            confess "Error trying to decode json string:\n$json_left\n$@";
        }
        
        eval {
            $right_genes_aref = $JSON_DECODER->decode($json_right);
        };
        if ($@) {
            confess "Error decoding json string:\n$json_right\n$@";
        }
        
        my ($rst_A, $cigar_A) = ($x[10], $x[11]);
        my ($rst_B, $cigar_B) = ($x[12], $x[13]);

        
        my ($genome_coords_A_aref, $read_coords_A_aref) = &get_genome_coords_via_cigar($rst_A, $cigar_A);
        my ($genome_coords_B_aref, $read_coords_B_aref) = &get_genome_coords_via_cigar($rst_B, $cigar_B);
                
        
        foreach my $left_gene_struct (@$left_genes_aref) {

            my $left_gene_id = $left_gene_struct->{gene_id};

            $left_gene_id =~ s/\^.*$//;
            
            foreach my $right_gene_struct (@$right_genes_aref) {
                
                my $right_gene_id = $right_gene_struct->{gene_id};
                $right_gene_id =~ s/\^.*$//;
                
                print join("\t", $left_gene_id, $chrom_left, $strand_left, &dump_coords($genome_coords_A_aref), 
                           &dump_coords($read_coords_A_aref), 
                           $chrom_right, $strand_right, &dump_coords($genome_coords_B_aref),
                           &dump_coords($read_coords_B_aref))
                    . "\n";
                                
            }
        }
    }
    

    exit(0);
}



####
sub dump_coords {
    my ($coords_aref) = @_;

    my @coord_strs;
    foreach my $coordpair (@$coords_aref) {
        my ($lend, $rend) = @$coordpair;
        push (@coord_strs, "$lend-$rend");
    }

    return(join(",", @coord_strs));
}
