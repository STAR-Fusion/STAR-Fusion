#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use Data::Dumper;

my $usage = "\n\tusage: $0 chimJ_file star-fusion_outdir\n\n";

my $chimJ_file = $ARGV[0] or die $usage;
my $star_fusion_outdir = $ARGV[1] or die $usage;


my $count_sub = sub {
    my ($file) = @_;
    
    print STDERR "count_FFPM_filtered() - parsing $file\n";
    
    open(my $fh, $file) or confess "Error, cannot open file: $file";
    my $header = <$fh>;
    my %fusions;
    while(<$fh>) {
        my @x = split(/\t/);
        my $fusion = $x[0];
        $fusions{$fusion}++;
    }
        close $fh;
    
    return(scalar(keys %fusions));
};


main: {
     
     my %audit;
               
     &get_total_reads($chimJ_file, \%audit);

     &audit_chimeric_alignments($chimJ_file, \%audit, "total_chim_reads");
     
     &audit_failed_read_alignments("$star_fusion_outdir/star-fusion.preliminary/star-fusion.junction_breakpts_to_genes.txt.fail", \%audit);

     &audit_chimeric_alignments("$star_fusion_outdir/star-fusion.preliminary/star-fusion.junction_breakpts_to_genes.txt.pass", \%audit, "chim_reads_passed");
     
     &count_prelim_fusions("$star_fusion_outdir/star-fusion.preliminary/star-fusion.fusion_candidates.preliminary", \%audit);
     
     
     ## applied basic filtering criteria (ie. min support)
     &count_pre_blast_filt("$star_fusion_outdir/star-fusion.preliminary/star-fusion.filter.intermediates_dir/star-fusion.pre_blast_filter.filt_info", \%audit);

     my $total_remaining_after_basic_filtering = &$count_sub("$star_fusion_outdir/star-fusion.preliminary/star-fusion.filter.intermediates_dir/star-fusion.pre_blast_filter");
     
     ## remove those that are lesser scored paralogs of fusion partners
     &count_blast_filt("$star_fusion_outdir/star-fusion.preliminary/star-fusion.filter.intermediates_dir/star-fusion.pre_blast_filter.post_blast_filter.info", \%audit);
     $audit{'remaining_post_blast_filt'} = &$count_sub("$star_fusion_outdir/star-fusion.preliminary/star-fusion.filter.intermediates_dir/star-fusion.pre_blast_filter.post_blast_filter");
     
     
     
     &count_promiscuous_filt("$star_fusion_outdir/star-fusion.preliminary/star-fusion.filter.intermediates_dir/star-fusion.pre_blast_filter.post_blast_filter.post_promisc_filter.info", \%audit);
     $audit{'remaining_post_promisc_filt'} = &$count_sub("$star_fusion_outdir/star-fusion.preliminary/star-fusion.filter.intermediates_dir/star-fusion.pre_blast_filter.post_blast_filter.post_promisc_filter");
     
     

     &count_red_herrings("$star_fusion_outdir/star-fusion.preliminary/star-fusion.fusion_candidates.preliminary.wSpliceInfo.wAnnot.annot_filt", \%audit);
     $audit{'remaining_post_red_herrings'} = &$count_sub("$star_fusion_outdir/star-fusion.preliminary/star-fusion.fusion_candidates.preliminary.wSpliceInfo.wAnnot.pass");
     
     
     &count_FFPM_filtered("$star_fusion_outdir/star-fusion.preliminary/star-fusion.fusion_candidates.preliminary.wSpliceInfo.wAnnot.pass",
                          "$star_fusion_outdir/star-fusion.preliminary/star-fusion.fusion_candidates.preliminary.wSpliceInfo.wAnnot.pass.minFFPM.0.1.pass",
                          \%audit);

     
     my $total_final_fusions = &$count_sub("$star_fusion_outdir/star-fusion.fusion_predictions.abridged.tsv");
     

     ##########
     ## Reporting
     #############

     
     my $report = "";
     
     ## starting read counts:
     # 'Nreads' => '21430514',
     # 'NreadsUnique' => '17249407',
     # 'NreadsMulti' => '1094325',

     my $num_mapped_reads = $audit{'NreadsUnique'} + $audit{'NreadsMulti'};
     
     $report .= "# Read Counts\n"
         . "Nreads:\t" . $audit{'Nreads'} . "\n"
         . "NreadsUnique:\t" . $audit{'NreadsUnique'} . "\n"
         . "NreadsMulti:\t" . $audit{'NreadsMulti'} . "\n"
         . "\n";
     
     $report .= "pct reads mapped:\t" . sprintf("%.2f", $num_mapped_reads / $audit{'Nreads'} * 100) . "\n\n";
     
     $report .= "chimeric read count:\t" . $audit{'total_chim_reads'} . "\t" . sprintf("%.2f", $audit{'total_chim_reads'} / $num_mapped_reads * 100) . " \n\n";
     
     ## Read filtering 
     # 'read_fail__no_gene_anchors' => 1087355,
     # 'read_fail__selfie_or_homology' => 145793,
     # 'read_fail__discarded_multimap_deficient_anchors' => 53221,
     # 'read_fail__multimap_homology_congruence_fail' => 6523,

     
     
     $report .= "# read filtering\n"
         . "no anchors:\t" . $audit{'read_fail__no_gene_anchors'} . "\n"
         . "selfie or homolog:\t" . $audit{'read_fail__selfie_or_homology'} . "\n"
         . "multimap deficient anchors:\t" . $audit{'read_fail__discarded_multimap_deficient_anchors'} . "\n"
         . "multimap homology congruence:\t" . $audit{'read_fail__multimap_homology_congruence_fail'} . "\n"
         . "\n";

     $report .= "chimeric reads passed:\t" . $audit{'chim_reads_passed'} . "\t = " . sprintf("%.2f", $audit{'chim_reads_passed'} / $audit{'total_chim_reads'} * 100) . "\n";
     
     ## initial fusion candidates:
     # 'prelim_fusion_count' => 131313,

     $report .= "# initial fusion candidates\n"
         . "prelim fusion count:\t" . $audit{'prelim_fusion_count'} . "\n"
         . "\n";
     
     ## Basic filtering applied.
     # 'pre_blast::insuf_sum_support' => 125407,
     # 'pre_blast::insuf_novel_junc_support' => 5789,
     # 'pre_blast::no_junction_support' => 4377,
     # 'pre_blast::no_span_no_LDAS' => 40,
     # 'pre_blast::low_pct_isoform' => 1

     $report .= "# basic filtering criteria applied.\n"
         . "insufficient sum support:\t" . $audit{'pre_blast::insuf_sum_support'} . sprintf("\t%.2f", $audit{'pre_blast::insuf_sum_support'}/$audit{'prelim_fusion_count'} * 100) . "\n"
         . "insufficient novel junction support:\t" . $audit{'pre_blast::insuf_novel_junc_support'} . sprintf("\t%.2f", $audit{'pre_blast::insuf_novel_junc_support'}/$audit{'prelim_fusion_count'} * 100) . "\n"
         . "no junction support:\t" . $audit{'pre_blast::no_junction_support'} . sprintf("\t%.2f", $audit{'pre_blast::no_junction_support'}/$audit{'prelim_fusion_count'} * 100) . "\n"
         . "no span, no LDAS:\t" . $audit{'pre_blast::no_span_no_LDAS'} . sprintf("\t%.2f", $audit{'pre_blast::no_span_no_LDAS'} / $audit{'prelim_fusion_count'}  * 100) . "\n"
         . "low pct isoform:\t" . $audit{'pre_blast::low_pct_isoform'} . sprintf("\t%.2f", $audit{'pre_blast::low_pct_isoform'} / $audit{'prelim_fusion_count'} * 100) .  "\n";


     
     my $total_basic_filtered = $audit{'prelim_fusion_count'} - $total_remaining_after_basic_filtering;

     $report .= "-------------------------------------------\n"
         . "total basic filtered:\t" . $total_basic_filtered . sprintf("\t%.2f", $total_basic_filtered / $audit{'prelim_fusion_count'} * 100) . "\n"
         . "\n";
     
     $report .= "\tnum fusion candidates remaining:\t$total_remaining_after_basic_filtering\n\n";
     
     
     $report .= "# Final feature filters.\n"
         ## blast filter   A--B exists, removing C--B where A,C are paralogs and score(C--B) < score(A--B) 
         # 'blast_filt' => 27,
         
         . "blast paralog filter:\t" . $audit{'blast_filt'} . ", remaining post blast filt: " . $audit{'remaining_post_blast_filt'} . "\n"
         
         ## promiscuity filter
         # 'promisc_filt' => 4, 
         . "promiscuity filter:\t" . $audit{'promisc_filt'} . ", remaining post promisc filt: " . $audit{'remaining_post_promisc_filt'} . "\n"
         
         ## red herring annotation filter:
         ## 'red_herrings_filt' => 27,
         . "red herrings filter:\t" . $audit{'red_herrings_filt'} . ", remaining post red herring filt: " . $audit{'remaining_post_red_herrings'} . "\n"
         
         ## final expression filter
         # 'FFPM_filt' => 5,
         . "FFPM filter:\t" . $audit{'FFPM_filt'} . "\n"

         . "\n";

     $report .= "Final fusions called:\t" . $total_final_fusions . "\n\n";
     

     print $report;
     
}



####
sub count_FFPM_filtered {
    my ($file_before, $file_after, $audit_href) = @_;
        

    my $count_before = &$count_sub($file_before);
    my $count_after = &$count_sub($file_after);

    $audit_href->{FFPM_filt} = ($count_before - $count_after);

    return;
}


####
sub count_red_herrings {
    my ($file, $audit_href) = @_;
    
    print STDERR "count_red_herrings() - parsing $file\n";
    
    my %fusions;
    
    open(my $fh, $file) or confess "Error, cannot open file: $file";
    my $header = <$fh>;
    while(<$fh>) {
        my @x = split(/\t/);
        my $fusion = $x[0];
        $fusions{$fusion}++;
    }
    close $fh;

    my $num_fusions = scalar(keys %fusions);
    
    $audit_href->{"red_herrings_filt"} = $num_fusions;
    
    return;
}


####
sub count_promiscuous_filt {
    my ($file, $audit_href) = @_;
    
    print STDERR "count_promiscuous_filt() - parsing $file\n";
    
    my %fusions;
    
    open(my $fh, $file) or confess "Error, cannot open file: $file";
    my $header = <$fh>;
    while(<$fh>) {
        chomp;
        if (/^\#(\S+)/) {
            my $fusion_name = $1;
            $fusions{$fusion_name}++;
        }
    }
    close $fh;

    my $num_fusions = scalar(keys %fusions);

    $audit_href->{"promisc_filt"} = $num_fusions;
    
    return;
}
    


####
sub count_blast_filt {
    my ($file, $audit_href) = @_;

    print STDERR "count_blast_filt() - parsing $file\n";
    
    my %fusions;
    
    open(my $fh, $file) or confess "Error, cannot open file: $file";
    my $header = <$fh>;
    while(<$fh>) {
        chomp;
        if (/^\#(\S+)/) {
            my $fusion_name = $1;
            $fusions{$fusion_name}++;
        }
    }
    close $fh;

    my $num_fusions = scalar(keys %fusions);

    $audit_href->{"blast_filt"} = $num_fusions;

    return;
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
sub audit_chimeric_alignments {
    my ($chimJ_file, $audit_href, $token) = @_;

    print STDERR "audit_chimeric_alignments() - parsing $chimJ_file\n";

    my $count = 0;
    
    open(my $fh, $chimJ_file) or die $!;
    my $prev_read = "";
    while(<$fh>) {
        unless (/\w/) { next; }
        if (/^\#/) { next; }
        my @x = split(/\t/);
        my $read_name = $x[9];
        if ($read_name ne $prev_read) {
            $count++;
        }
        $prev_read = $read_name;
    }
    close $fh;

    $audit_href->{$token} = $count;

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
        $seen{$fusion}=1;
    }
    
    return;
}
