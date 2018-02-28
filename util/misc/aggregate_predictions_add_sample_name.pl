#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../PerlLib";
use DelimParser;

my $usage = "usage: $0 tsv_file_list_file.txt [sample_name_idx=-2]\n\n";

my $fi_files_list = $ARGV[0] or die $usage;
my $sample_name_idx = $ARGV[1] || -2;

main: {

    my $tab_writer;
    
    my $seen_header_flag = 0;
    
    open (my $fh, $fi_files_list) or die $!;
    while (<$fh>) {
        chomp;
        my $filename = $_;
        my @pts = split(/\//, $filename);
        my $sample_name = $pts[$sample_name_idx];
        
        unless (-s $filename) {
            print STDERR "\n\n\tooops... file $filename isn't there any more.\n\n";
            next;
        }
        
        open (my $fh2, $filename) or die "Error, cannot open filename: $filename";
        print STDERR "-processing $filename\n";
        my $tab_reader = new DelimParser::Reader($fh2, "\t");
        if (! $seen_header_flag) {
            my @fields = $tab_reader->get_column_headers();
            unshift(@fields, "#sample");
            $tab_writer = new DelimParser::Writer(*STDOUT, "\t", \@fields);
            $seen_header_flag = 1;
        }
        while (my $row = $tab_reader->get_row()) {
            
            $row->{'#sample'} = $sample_name;
            $tab_writer->write_row($row);
        }
        close $fh2;
    }
    close $fh;
    
    
    exit(0);
}
