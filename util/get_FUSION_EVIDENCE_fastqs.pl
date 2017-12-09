#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use Fastq_reader;
use Process_cmd;
use DelimParser;
use Carp;
use Data::Dumper;

use Getopt::Long qw(:config posix_default no_ignore_case bundling pass_through);  


my $usage = <<__EOUSAGE__;

######################################################################################
#
#  --fusions <string>           fusion predictions 'final' output file (not abridged)
#
#  Reads:
#
#     --left_fq <string>           /1 fastq file (or SE reads)
#
#     --right_fq <string>          /2 fastq file (optional, required for PE reads)
#
#   or
#     --samples_file <string>
#
#
#  --output_prefix <string>     output prefix
#
######################################################################################

__EOUSAGE__

    ;


my $help_flag;

my $fusion_results_file;
my $left_fq;
my $right_fq;
my $output_prefix;
my $samples_file;

&GetOptions( 'help|h' => \$help_flag,

             'fusions=s' => \$fusion_results_file,
             
             'left_fq=s' => \$left_fq,
             'right_fq=s' => \$right_fq,
             
             'samples_file=s' => \$samples_file,

             'output_prefix=s' => \$output_prefix,
    );

if ($help_flag) {
    die $usage;
}

unless ($fusion_results_file && ($left_fq  || $samples_file) && $output_prefix) {
    die $usage;
}


main: {

    ## get the core fragment names:
    my %core_frag_name_to_fusion_name;

    open (my $fh, $fusion_results_file) or die "Error, cannot open file $fusion_results_file";
    my $tab_reader = new DelimParser::Reader($fh, "\t");

    while (my $row = $tab_reader->get_row()) {
        my $fusion_name = $row->{'#FusionName'} or die "Error, cannot get fusion name from " . Dumper($row);
        
        my $junction_reads_list_txt = $row->{JunctionReads};
        
        foreach my $junction_read (split(/,/, $junction_reads_list_txt)) {

            if ($junction_read eq '.') { next; }
            
            $junction_read =~ s/^\&[^\@]+\@//; # remove any sample encoding here.
            
            my $pair_end = "";
            if ($junction_read =~ /^(\S+)\/([12])$/) {
                $junction_read = $1;
                $pair_end = $2;
            }
            my $updated_frag_name = "$fusion_name|J";
            if ($pair_end) {
                $updated_frag_name .= $pair_end;
            }
            $updated_frag_name .= "|$junction_read";

            $core_frag_name_to_fusion_name{$junction_read} = $updated_frag_name;
        }
        
        my $spanning_frag_list_txt = $row->{SpanningFrags};
        foreach my $spanning_frag (split(/,/, $spanning_frag_list_txt)) {

            if ($spanning_frag eq '.') { next; }
            
            $spanning_frag =~ s/^\&[^\@]+\@//; # remove any sample encoding here.
            my $updated_frag_name = "$fusion_name|S|$spanning_frag";
            $core_frag_name_to_fusion_name{$spanning_frag} = $updated_frag_name;
        }
    }


    my $sample_names = "";;
    
    if ($samples_file) {
        ($sample_names, $left_fq, $right_fq) = &parse_samples_file($samples_file);
    }
    
    &write_fastq_files($left_fq, "$output_prefix.fusion_evidence_reads_1.fq", \%core_frag_name_to_fusion_name, $sample_names);
    
    if ($right_fq) {
        &write_fastq_files($right_fq, "$output_prefix.fusion_evidence_reads_2.fq", \%core_frag_name_to_fusion_name, $sample_names);
    }
    
    print STDERR "\nDone.\n\n";
    
    exit(0);
    
}


####
sub write_fastq_files {
    my ($input_fastq_files, $output_fastq_file, $core_frag_name_to_fusion_name_href, $sample_names) = @_;


    my @samples = split(/,/, $sample_names);
    
    open (my $ofh, ">$output_fastq_file") or die "Error, cannot write to $output_fastq_file";

    my %reads_to_capture = %{$core_frag_name_to_fusion_name_href};
    
    
    foreach my $input_fastq_file (split(/,/, $input_fastq_files)) {
        print STDERR "-searching fq file: $input_fastq_file\n";
        my $sample_name = shift @samples;
        
        my $fastq_reader = new Fastq_reader($input_fastq_file);
        
        while (my $fq_record = $fastq_reader->next()) {
            
            my $core_read_name = $fq_record->get_core_read_name();
            #print STDERR "[$core_read_name]\n";
            
            if (my $fusion_name = $core_frag_name_to_fusion_name_href->{$core_read_name}) {

                delete $reads_to_capture{$core_read_name} if exists $reads_to_capture{$core_read_name};
                
                my $record_text = $fq_record->get_fastq_record();
                chomp $record_text;
                my @lines = split(/\n/, $record_text);
                my ($_1, $_2, $_3, $_4) = @lines;

                if ($sample_name) {
                    # encode it in the read name:
                    $_1 =~ s/^\@/\@\&${sample_name}\@/;
                }
                $_3 = "+$fusion_name"; # encode the fusion name in the 3rd line, which is otherwise useless anyway
                print $ofh join("\n", ($_1, $_2, $_3, $_4)) . "\n";
            }
        }
        
        
    }

    print STDERR "\nDone writing to $output_fastq_file\n\n";

    if (%reads_to_capture) {
        confess "Error, failed to capture fusion evidence reads: " . Dumper(\%reads_to_capture);
    }
    
    return;
}


####
sub append_reads_to_fusion {
    my ($fusion_name, $core_frag_name_to_fusion_name_href, $reads_href) = @_;

    foreach my $frag_name (keys %$reads_href) {
        $core_frag_name_to_fusion_name_href->{$frag_name} = $fusion_name ;
    }
    
    return;
}

####
sub parse_core_frag_names {
    my ($comma_delim_read_list_txt) = @_;

    my %core_frag_names;

    my @read_names = split(/,/, $comma_delim_read_list_txt);
    foreach my $read_name (@read_names) {
        $read_name =~ s|/[12]$||;
        $core_frag_names{$read_name} = 1;
    }

    
    return(%core_frag_names);
}


####
sub parse_samples_file {
    my ($samples_file) = @_;

    my @sample_names;
    my @left_fqs;
    my @right_fqs;
    
    open(my $fh, $samples_file) or die "Error, cannot open file: $samples_file";
    while (<$fh>) {
        chomp;
        my @x = split(/\t/);
        my ($sample_name, $left_fq, $right_fq) = @x;

        push (@sample_names, $sample_name);
        
        push (@left_fqs, $left_fq);
        
        if ($right_fq) {
            push (@right_fqs, $right_fq);
        }
    }

    my $sample_names_txt = join(",", @sample_names);
    my $left_fq_files = join(",", @left_fqs);
    my $right_fq_files = join(",", @right_fqs);


    return($sample_names_txt, $left_fq_files, $right_fq_files);
}
