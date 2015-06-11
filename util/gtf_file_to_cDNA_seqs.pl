#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib ("$FindBin::Bin/../lib");
use Gene_obj;
use Gene_obj_indexer;
use GTF_utils;
use CdbTools;
use Carp;

my $usage = "\n\nusage: $0 gtf_file genome_db [prot|CDS|cDNA|gene,default=prot]\n\n";

my $gff3_file = $ARGV[0] or die $usage;
my $fasta_db = $ARGV[1] or die $usage;
my $seq_type = $ARGV[2] || "prot";


unless ($seq_type =~ /^(prot|CDS|cDNA|gene)$/) {
    die "Error, don't understand sequence type [$seq_type]\n\n$usage";
}

my $index_file = "$gff3_file.inx";

my $gene_obj_indexer = undef;

if (-s $index_file) {
    ## try to use it
    $gene_obj_indexer = new Gene_obj_indexer( { "use" => $index_file } );
    my @gene_ids = $gene_obj_indexer->get_keys();
    unless (@gene_ids) {
        $gene_obj_indexer = undef; # didn't work, must create a new index file
        print STDERR "Even though $index_file exists, couldn't use it.  Going to have to regenerate it now.\n";
    }
}

unless ($gene_obj_indexer) {
    
    $gene_obj_indexer = new Gene_obj_indexer( { "create" => $index_file } );
    
    ## associate gene identifiers with contig id's.
    &GTF_utils::index_GTF_gene_objs($gff3_file, $gene_obj_indexer);
}

## associate all gene_ids with contigs
my @all_gene_ids = $gene_obj_indexer->get_keys();
my %contig_to_gene_list;
foreach my $gene_id (@all_gene_ids) {
    my $gene_obj = $gene_obj_indexer->get_gene($gene_id);
    
    my $contig = $gene_obj->{asmbl_id} 
    or croak "Error, can't find contig id attached to gene_obj($gene_id) as asmbl_id val\n" 
        . $gene_obj->toString();
    
    
    my $gene_list_aref = $contig_to_gene_list{$contig};
    unless (ref $gene_list_aref) {
        $gene_list_aref = $contig_to_gene_list{$contig} = [];
    }

    push (@$gene_list_aref, $gene_id);

}



foreach my $asmbl_id (sort keys %contig_to_gene_list) {
    
    my $genome_seq = cdbyank_linear($asmbl_id, $fasta_db);
    
    my @gene_ids = @{$contig_to_gene_list{$asmbl_id}};
    
    foreach my $gene_id (@gene_ids) {
        my $gene_obj_ref = $gene_obj_indexer->get_gene($gene_id);

        my %params;
        if ($seq_type eq "gene") {
            $params{unspliced_transcript} = 1;
        }
        
        $gene_obj_ref->create_all_sequence_types(\$genome_seq, %params);
        
        foreach my $isoform ($gene_obj_ref, $gene_obj_ref->get_additional_isoforms()) {
            
            my $isoform_id = $isoform->{Model_feat_name};
            my $gene_id = $isoform->{TU_feat_name};
            
            
            my $seq = "";

            if ($seq_type eq "prot") {
                $seq = $isoform->get_protein_sequence();
            }
            elsif ($seq_type eq "CDS") {
                $seq = $isoform->get_CDS_sequence();
            }
            elsif ($seq_type eq "cDNA") {
                $seq = $isoform->get_cDNA_sequence();
            }
            elsif ($seq_type eq "gene") {
                $seq = $isoform->get_gene_sequence();
            }
            
            $seq =~ s/(\S{60})/$1\n/g; # make fasta format
            chomp $seq;
            
            my $com_name = $isoform->{com_name} || "";
            
            my $gene_name = $isoform->{gene_name};
            my $header = ">$isoform_id $gene_id";
            if ($gene_name) {
                $header .= " $gene_name ";
            }
            if ($com_name) {
                $gene_name .= " $com_name";
            }
            
            print "$header\n$seq\n";
        }
    }
}


exit(0);

