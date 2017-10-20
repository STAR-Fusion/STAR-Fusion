#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use Fastq_reader;

my $usage = "usage: $0 file.fastq\n\n";

my $fq_file = $ARGV[0] or die $usage;

my $fq_reader = new Fastq_reader($fq_file);

while (my $fq_record = $fq_reader->next()) {

    my $record_text = $fq_record->get_fastq_record();

    $record_text =~ s/^\@/\@merged-/;

    print $record_text;
}

exit(0);

