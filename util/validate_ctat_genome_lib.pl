#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use TiedHash;

my $usage = "\n\n\tusage: $0 /path/to/ctat_genome_lib_build_dir/\n\n";

my $genome_lib_dir = $ARGV[0] or die $usage;


main: {

    chdir $genome_lib_dir or die "Error, cannot cd to $genome_lib_dir";
    
    my @required_dbs = ("fusion_annot_lib.idx",
                        "blast_pairs.idx",
                        "trans.blast.align_coords.align_coords.dbm",
                        "pfam_domains.dbm");

    
    foreach my $db (@required_dbs) {
        
        unless (-s $db) {
            die "** Error, not able to find file: $db ** ";
        }
        
        my $idx = new TiedHash( { use => $db } );
        my $simple_annotation_text = $idx->get_value("geneABC--geneXYZ");
        unless ($simple_annotation_text) {
            confess("\n\t*** Error, FusionAnnot lib [$db] doesnt appear to be working. Rebuilding fusion annot lib will be required");
        }
    }


    print STDERR "-ctat genome lib [$genome_lib_dir] validates.\n";
    
    exit(0);
}
