#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib ("$FindBin::Bin/../lib");
use TiedHash;
use Carp;
use Fasta_reader;

my $usage = "\n\n\tusage: $0 cdna.fasta\n\n";

my $cdna_fasta = $ARGV[0] or die $usage;

main: {

    my $idx = new TiedHash( { create => "$cdna_fasta.idx" } );
    
    my %gene_to_seqs = &parse_cdna_seqs_by_gene($cdna_fasta);

    foreach my $gene_key (keys %gene_to_seqs) {
        my $seqs = $gene_to_seqs{$gene_key};
        $idx->store_key_value($gene_key, $seqs);
    }
    
    print STDERR "-done creating index file: $cdna_fasta.idx\n\n";

    exit(0);
    
}


####
sub parse_cdna_seqs_by_gene {
    my ($cdna_fasta_file) = @_;

    my %gene_to_seqs;

    my $fasta_reader = new Fasta_reader($cdna_fasta_file);
    
    while (my $seq_obj = $fasta_reader->next()) {

        my $header = $seq_obj->get_header();

        my $sequence = $seq_obj->get_sequence();

        $header =~ s/^>//;
        
        my ($trans_id, $gene_id, $gene_name, @rest) = split(/\s+/, $header);
        unless ($gene_id) {
            confess "Error, need format '>trans_id gene_id [gene_name] ... for the header, found:\n$header\n";
        }
        
        my @acc_tokens = ($gene_id, $trans_id);
        if ($gene_name && $gene_name ne $gene_id) {
            unshift(@acc_tokens, $gene_name);
        }
        my $acc = join("::", @acc_tokens);
        
        my $fasta_record = ">$acc\n$sequence\n";
        
        $gene_to_seqs{$gene_id} .= $fasta_record; 
        
        if ($gene_name && $gene_name ne $gene_id) {
            $gene_to_seqs{$gene_name} .= $fasta_record;
        }
        
    }
    
    return(%gene_to_seqs);
}

