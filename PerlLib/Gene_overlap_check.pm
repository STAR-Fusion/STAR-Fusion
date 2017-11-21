#!/usr/bin/env perl

package Gene_overlap_check;

use strict;
use warnings;


my %GENE_TO_SPAN_INFO;

my $singleton_obj = undef;

sub new {
    my ($packagename, $gene_span_file) = @_;

    if ($singleton_obj) {
        return($singleton_obj);
    }
    else {
        $singleton_obj = {};
        bless ($singleton_obj, $packagename);
        
        &_parse_gene_span_info($gene_span_file);
        
        return($singleton_obj);
    }
    
}


####
sub get_gene_span_info {
    my ($self, $gene_id) = @_;

    my $struct = $GENE_TO_SPAN_INFO{$gene_id} or die "Error, no gene span info stored for gene $gene_id";
    return($struct);
}


####
sub are_genes_overlapping {
    my ($self, $geneA, $geneB) = @_;
    
    my $genome_span_A_href = $GENE_TO_SPAN_INFO{$geneA} or die "Error, no gene span info found for $geneA";
    my $genome_span_B_href = $GENE_TO_SPAN_INFO{$geneB} or die "Error, no gene span info found for $geneB";
    
    if ($genome_span_A_href->{chr} eq $genome_span_B_href->{chr}

        &&

        ## coordinate overlap testing
        $genome_span_A_href->{lend} < $genome_span_B_href->{rend}
        &&   
        $genome_span_A_href->{rend} > $genome_span_B_href->{lend}   
        
        ) {
        
        return(1);
    }
    else {
        return(0);
    }

}






############ PRIVATE 

####
sub _parse_gene_span_info {
    my ($gene_spans_file) = @_;
        
    open (my $fh, $gene_spans_file) or die "Error, cannot open file: $gene_spans_file .... be sure to have run prep_genome_lib.pl to generate it";
    while (<$fh>) {
        chomp;
        my @x = split(/\t/);
        my $gene_symbol = $x[5];
        my $chr = $x[1];
        my ($lend, $rend) = sort {$a<=>$b} ($x[2], $x[3]); # should already be sorted, but just in case.
        
        $GENE_TO_SPAN_INFO{$gene_symbol} = { chr => $chr,
                                             lend => $lend,
                                             rend => $rend };
        
    }
    
    close $fh;

    return;
}


1; #EOM

