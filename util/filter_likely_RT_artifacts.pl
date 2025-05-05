#!/usr/bin/env perl

use strict;
use warnings;
use Carp;

use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use DelimParser;

use Getopt::Long qw(:config posix_default no_ignore_case bundling pass_through);

my $genome_lib_dir = $ENV{CTAT_GENOME_LIB};



my $usage = <<__EOUSAGE__;

#############################################################################
 
   writes .RTartifact.pass and .RTartifact.filtered files)

#############################################################################
#
#  --fusions <string>               preliminary fusion predictions
#
#  --genome_lib_dir <string>        genome lib dir (default: ${genome_lib_dir})       
#
#############################################################################

__EOUSAGE__
    
    ;


my $fusion_preds_file;
my $help_flag;

&GetOptions ( 'help|h' => \$help_flag,
              'fusions=s' => \$fusion_preds_file,
              'genome_lib_dir=s' => \$genome_lib_dir,
    );

if ($help_flag) {
    die $usage;
}

unless ($genome_lib_dir && $fusion_preds_file) {
    die $usage;
}

my @FREE_PASS = qw(Mitelman chimerdb_omim chimerdb_pubmed ChimerKB ChimerPub
                   Cosmic HaasMedCancer); # TODO: put in config, currently sharing this here and w/ AnnotFilterRule

my $FREE_PASS_REGEX = join("|", @FREE_PASS);

#print "$FREE_PASS_REGEX\n";



############################################################
## Need AnnotFilterRule for organism-specific exceptions to filtering rules based on genes

my $annot_filt_module = "$genome_lib_dir/AnnotFilterRule.pm";
unless (-s $annot_filt_module) {
    die "Error, cannot locate required $annot_filt_module  ... be sure to use a more modern version of the companion CTAT_GENOME_LIB ";
}

require $annot_filt_module;
############################################################



sub fusion_has_junction_reads_exception {
    my ($fusion) = @_;

    # these are fusions that are known to  have complex breakpoints, so we make an exception for them.
    
    if ($fusion =~ /IGH|DUX4/) {
        return(1);
    }
    
    return(0); # by default, no exemption given.
}




main: {
    
    open(my $fh, $fusion_preds_file) or die "Error, cannot open file: $fusion_preds_file";
    my $delim_reader = new DelimParser::Reader($fh, "\t");

    my @column_headers = $delim_reader->get_column_headers();

    my $pass_file = "$fusion_preds_file.RTartifact.pass";
    open(my $pass_ofh, ">$pass_file") or die "Error, cannot write to $pass_file";
    my $pass_writer = new DelimParser::Writer($pass_ofh, "\t", \@column_headers);
    
    
    my $filtered_file = "$fusion_preds_file.RTartifact.filtered";
    open(my $filtered_ofh, ">$filtered_file") or die "Error, cannot write to $filtered_file";
    my $filtered_writer = new DelimParser::Writer($filtered_ofh, "\t", \@column_headers);


    my @rows;
    
    while (my $row = $delim_reader->get_row()) {
        push (@rows, $row);
    }

    ## prioritize according to number of junction (split) reads:
    @rows = reverse sort {$a->{JunctionReadCount} <=> $b->{JunctionReadCount}} @rows;
    

    my %passed;
    my %failed;

    my @passed_rows;
    my @filtered_rows;
    
    foreach my $row (@rows) {
        
        my $left_dinuc = uc $delim_reader->get_row_val($row, "LeftBreakDinuc");
        my $right_dinuc = uc $delim_reader->get_row_val($row, "RightBreakDinuc");
        
        my $fusion_name = $delim_reader->get_row_val($row, "#FusionName");

        my $annots = $delim_reader->get_row_val($row, "annots");
        
        #print STDERR "$annots";
        
        my $combo = $left_dinuc . $right_dinuc;

        if (exists $failed{$fusion_name}) {
            push(@filtered_rows, $row);
            next;
        }

        my $pass_flag = 0;
        
        if ($combo =~ /^(GTAG|GCAG|ATAC)$/
                ||
            ## allow for known cases of peculiar fusions.
            $fusion_name =~ /\@/ # includes the IGH and IGL super loci

            ||
            
            $annots =~ /\b($FREE_PASS_REGEX)\b/
            
            ||

            &fusion_has_junction_reads_exception($fusion_name) # (IGH or DUX4 fusions tend to lack spliced breakpoints)

            ||
            
            &AnnotFilterRule::fusion_has_junction_reads_exception($fusion_name) # ie. IGH--CRLF2
            
            ) {

            $pass_flag = 1;
            
        }
        

        if ($pass_flag) {
            $passed{$fusion_name} = 1;
            push (@passed_rows, $row);
        }
        else {
            # we only fail those that are dominant non-canonical splice.
            if (! exists $passed{$fusion_name}) {
                $failed{$fusion_name} = 1;
            }
            push (@filtered_rows, $row);
        }
    }

    ## write output files..

    foreach my $row (@passed_rows) {
        $pass_writer->write_row($row);
    }

    foreach my $row (@filtered_rows) {
        $filtered_writer->write_row($row);
    }

    my $pass_counter = scalar(@passed_rows);
    my $filtered_counter = scalar(@filtered_rows);
    
    print STDERR "-filter_likely_RT_artifacts: (pass: $pass_counter, filtered: $filtered_counter)\n";
    
    exit(0);
}

