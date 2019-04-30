#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use Data::Dumper;

my $usage = "\n\tusage: $0 chimJ_file star-fusion_outdir\n\n";

my $chimJ_file = $ARGV[0] or die $usage;
my $star_fusion_outdir = $ARGV[1] or die $usage;



 main: {
     
     my %audit;

     &count_pre_blast_filt("$star_fusion_outdir/star-fusion.preliminary/star-fusion.filter.intermediates_dir/star-fusion.pre_blast_filter.filt_info", \%audit);
     
     &get_total_reads($chimJ_file, \%audit);
     
     &audit_failed_read_alignments("$star_fusion_outdir/star-fusion.preliminary/star-fusion.junction_breakpts_to_genes.txt.fail", \%audit);
     
     &count_prelim_fusions("$star_fusion_outdir/star-fusion.preliminary/star-fusion.fusion_candidates.preliminary", \%audit);

     
     
     print Dumper(\%audit);
     
     
}

####
sub count_prelim_fusions {
    my ($prelim_fusions_file, $audit_href) = @_;

    print STDERR "count_prelim_fusions() -parsing $prelim_fusions_file\n";
    my %fusions;
    
    open(my $fh, $prelim_fusions_file) or confess "Error, cannot open file: $prelim_fusions_file ";
    my $header = <$fh>;
    while(<$fh>) {
        my @x = split(/\t/);
        my $fusion_name = $x[0];
        $fusions{$fusion_name}++;
    }
    close $fh;
    
    my $num_prelim_fusions = scalar(keys %fusions);
    
    $audit_href->{prelim_fusion_count} = $num_prelim_fusions;
    
    return;
}




####
sub get_total_reads {
    my ($chimJ_file, $audit_href) = @_;

    print STDERR "get_total_reads() - parsing $chimJ_file\n";
    
    my $reads_line = `tail -n1 $chimJ_file`;
    if ($reads_line =~ /^\# Nreads (\d+)\s+NreadsUnique (\d+)\s+NreadsMulti (\d+)/) {
        $audit_href->{Nreads} = $1;
        $audit_href->{NreadsUnique} = $2;
        $audit_href->{NreadsMulti} = $3;
    }
    else {
        confess "Error, didnt extract read count from $chimJ_file:   $reads_line ";
    }
    
    return;
}

####
sub audit_failed_read_alignments {
    my ($file, $audit_href) = @_;

    print STDERR "audit_failed_read_alignments() - parsing $file\n";
    
    open(my $fh, $file) or die "Error, cannot open file: $file ";
    while(<$fh>) {
        unless (/^\#/) { next; } # only processing comments.
        
        if (/Contains selfie or homology match/) {
            $audit_href->{read_fail__selfie_or_homology}++;
        }
        elsif (/only Pct \(0.00%\) of alignments had paired gene anchors/) {
            $audit_href->{read_fail__no_gene_anchors}++;
        }
        elsif (/only Pct .* of alignments had paired gene anchors/) {
            $audit_href->{read_fail__discarded_multimap_deficient_anchors}++;
        }
        elsif (/Fails mulitmapper homology congruence/) {
            $audit_href->{read_fail__multimap_homology_congruence_fail}++;
        }
        else {
            confess "not accounted for: $_";
        }
    }

    return;
}

####
sub count_pre_blast_filt {
    my ($file, $audit_href) = @_;

    print STDERR "count_pre_blast_filt() - parsing $file\n";

    my %seen;
    
    open(my $fh, $file) or die "Error, cannot open file: $file";
    my $header = <$fh>;
    while(<$fh>) {
        unless (/^\#/) { next; } # only examining filtered ones. 
        chomp;
        my @x = split(/\t/);
        my $fusion = $x[0];
        
        if ($seen{$fusion}) { next; }
        
        my $reason = $x[11];
        if ($reason eq 'Merged') { next; }

        my $token;
        
        if ($reason =~ /FILTERED DUE TO .*novel.* junction support/) {
            $token = "insuf_novel_junc_support";
        }
        elsif ($reason =~ /FILTERED DUE TO junction read support/) {
            $token = "no_junction_support";
        }
        elsif (/no spanning reads and no long double anchor support at breakpoint/) {
            $token = "no_span_no_LDAS";
        }
        elsif (/FILTERED DUE TO sum_support/) {
            $token = "insuf_sum_support";
        }
        elsif (/FILTERED DUE TO ONLY .* % of dominant isoform support/) {
            $token = "low_pct_isoform";
        }
        else {
            confess " error, not recognizing reasoning here: $reason ";
        }
        
        $audit_href->{"pre_blast::$token"}++;
    }
            
    return;
}
