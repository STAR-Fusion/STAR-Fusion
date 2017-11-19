#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../../PerlLib");
use Fastq_reader;

my $usage = "\n\n\tusage: $0 samples.txt fq_output_prefix\n\n";

my $samples_file = $ARGV[0] or die $usage;
my $fq_output_prefix = $ARGV[1] or die $usage;

main: {

    my ($left_fq_array_href, $right_fq_array_href) = &parse_samples_file($samples_file);

    &write_sample_encoded_fq($left_fq_array_href, "${fq_output_prefix}_1.fastq");

    if (@$right_fq_array_href) {
        &write_sample_encoded_fq($right_fq_array_href, "${fq_output_prefix}_2.fastq");
    }

    print STDERR "-done\n\n";

    exit(0);
}

####
sub parse_samples_file {
    my ($samples_file) = @_;

    my @left_fq_array;
    my @right_fq_array;
    
    open(my $fh, $samples_file) or die "Error, cannot open samples file: $samples_file";
    while (<$fh>) {
        chomp;
        my @x = split(/\t/);
        my ($sample_name, $left_fq_file, $right_fq_file) = split(/\s+/);

        push (@left_fq_array, [$sample_name, $left_fq_file]);

        if ($right_fq_file) {
            push (@right_fq_array, [$sample_name, $right_fq_file]);
        }

    }
    close $fh;

    return(\@left_fq_array, \@right_fq_array);

}

####
sub write_sample_encoded_fq {
    my ($fq_list_aref, $output_fq_filename) = @_;

    open(my $ofh, ">$output_fq_filename") or die "Error, cannot write to $output_fq_filename";

    foreach my $sample_fq (@$fq_list_aref) {
        my ($sample_name, $fq_file) = @$sample_fq;
        print STDERR "\t-processing file: $fq_file\n";
        
        my $fq_reader = new Fastq_reader($fq_file);

        while (my $record = $fq_reader->next()) {

            my $fq_text = $record->get_fastq_record();
            $fq_text =~ s/^\@/\@${sample_name}\^/ or die "Error, couldn't integrate sample_id into fq record: $fq_text";

            print $ofh $fq_text;
        }
    }
    close $ofh;

    print STDERR "-done writing file: $output_fq_filename\n";
    
    return;
}
