#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use Fastq_reader;
use Process_cmd;
use DelimParser;
use Data::Dumper;

my $usage = "\n\n\tusage: $0 fusion_predictions.final  left.fq right.fq output_prefix\n\n";

my $fusion_results_file = $ARGV[0] or die $usage;
my $left_fq = $ARGV[1] or die $usage;
my $right_fq = $ARGV[2] or die $usage;
my $output_prefix = $ARGV[3] or die $usage;


main: {

    ## get the core fragment names:
    my %core_frag_name_to_fusion_name;

    open (my $fh, $fusion_results_file) or die "Error, cannot open file $fusion_results_file";
    my $tab_reader = new DelimParser::Reader($fh, "\t");

    while (my $row = $tab_reader->get_row()) {
        my $fusion_name = $row->{'#FusionName'} or die "Error, cannot get fusion name from " . Dumper($row);

        my $junction_reads_list_txt = $row->{JunctionReads};
        
        foreach my $junction_read (split(/,/, $junction_reads_list_txt)) {
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
            my $updated_frag_name = "$fusion_name|S|$spanning_frag";
            $core_frag_name_to_fusion_name{$spanning_frag} = $updated_frag_name;
        }
    }
        
    &write_fastq_files($left_fq, "$output_prefix.fusion_evidence_reads_1.fq", \%core_frag_name_to_fusion_name);
    
    &write_fastq_files($right_fq, "$output_prefix.fusion_evidence_reads_2.fq", \%core_frag_name_to_fusion_name);
    

    print STDERR "\nDone.\n\n";
    
    exit(0);
    
}


####
sub write_fastq_files {
    my ($input_fastq_file, $output_fastq_file, $core_frag_name_to_fusion_name_href) = @_;
    
    my $fastq_reader = new Fastq_reader($input_fastq_file);

    open (my $ofh, ">$output_fastq_file") or die "Error, cannot write to $output_fastq_file";
    
    while (my $fq_record = $fastq_reader->next()) {
        
        my $core_read_name = $fq_record->get_core_read_name();
        #print "[$core_read_name]\n";
        
        if (my $fusion_name = $core_frag_name_to_fusion_name_href->{$core_read_name}) {

            my $record_text = $fq_record->get_fastq_record();
            chomp $record_text;
            my @lines = split(/\n/, $record_text);
            shift @lines;
            print $ofh join("\n", "\@${fusion_name}", @lines) . "\n";
        }
    }
    
    print STDERR "\nDone writing to $output_fastq_file\n\n";
    
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


