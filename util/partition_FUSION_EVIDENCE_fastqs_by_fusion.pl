#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use Fastq_reader;
use Process_cmd;

my $usage = "\n\n\tusage: $0 fusion_ev.left.fq fusion_ev.right.fq output_dir\n\n";

my $left_fq = $ARGV[0] or die $usage;
my $right_fq = $ARGV[1] or die $usage;
my $outdir_name = $ARGV[2] or die $usage;


main: {

    unless (-d $outdir_name) {
        &process_cmd("mkdir -p $outdir_name");
    }
        
    my $tmp_paired_fastq_tab_file = "tmp.$$.paired.fq.tab";
    open (my $ofh, ">$tmp_paired_fastq_tab_file") or die $!;
    
    
    my $left_fastq_reader = new Fastq_reader($left_fq);
    my $right_fastq_reader = new Fastq_reader($right_fq);
    
    while (my $left_fq_record = $left_fastq_reader->next()) {
        
        my $left_core_read_name = $left_fq_record->get_core_read_name();
        
        my $right_fq_record = $right_fastq_reader->next();
        
        my $right_core_read_name = $right_fq_record->get_core_read_name();
        if ($right_core_read_name ne $left_core_read_name) {
            die "Error, mismatched records: $left_core_read_name vs. $right_core_read_name";
        }
        
        my $left_record_text = $left_fq_record->get_fastq_record();
        my $right_record_text = $right_fq_record->get_fastq_record();
        
        chomp $left_record_text;
        $left_record_text =~ s/\n/$;/g;
        
        chomp $right_record_text;
        $right_record_text =~ s/\n/$;/g;
        
        print $ofh join("\t", $left_record_text, $right_record_text) . "\n";
        
    }

    close $ofh;

    my $sorted_tmp_file  = "$tmp_paired_fastq_tab_file.sorted";
    &process_cmd("sort $tmp_paired_fastq_tab_file > $sorted_tmp_file");


    ## write fastq files

    my $prev_fusion_name = "";
    my $left_ofh;
    my $right_ofh;
    
    open (my $fh, $sorted_tmp_file) or die $!;
    while (<$fh>) {
        chomp;
        my ($left_record, $right_record) = split(/\t/);

        my ($fusion_name, @rest) = split(/\|/, $left_record);
        $fusion_name =~ s/^\@//;
        
        if ($fusion_name ne $prev_fusion_name) {

            close $left_ofh if $left_ofh;
            close $right_ofh if $right_ofh;
                        
            my $fusion_reads_left_fq = "$outdir_name/${fusion_name}.left.fq";
            my $fusion_reads_right_fq = "$outdir_name/${fusion_name}.right.fq";
            open ($left_ofh, ">$fusion_reads_left_fq") or die $!;
            open ($right_ofh, ">$fusion_reads_right_fq") or die $!;

        }

        $left_record =~ s/$;/\n/g;
        $right_record =~ s/$;/\n/g;

        print $left_ofh "$left_record\n";
        print $right_ofh "$right_record\n";
        
        $prev_fusion_name = $fusion_name;
    }

    close $left_ofh if $left_ofh;
    close $right_ofh if $right_ofh;
    
    ## cleanup

    unlink($tmp_paired_fastq_tab_file);
    unlink($sorted_tmp_file);


    exit(0);
    
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


