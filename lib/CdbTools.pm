

=head1 NAME

package CdbTools

=cut



=head1 DESCRIPTION

    routines for extracting entries from Fasta file using the CDBtools cdbfasta and cdbyank.

=cut

    ;

package main;
our $SEE;


package CdbTools;

use strict;
use warnings;
require Exporter;

our @ISA = qw (Exporter);
our @EXPORT = qw (cdbyank linearize cdbyank_linear);

## cdbfasta and cdbyank must be in path, otherwise the system will die.

=over 4

=item cdbyank()

B<Description:> Retrieves a fasta sequence entry from a fasta database

B<Parameters:> accession, fastaFilename

B<Returns:> fastaEntry

use the linearize method to extract the fasta entry components

=back

=cut


    ;

sub cdbyank {
    my ($accession, $fastaFile) = @_;
    unless (-s "$fastaFile.cidx") {
        ## regenerate index file:
        my $cmd = "cdbfasta -C $fastaFile";
        my $ret = system $cmd;
        if ($ret) {
            die "Error, couldn't create index file: $cmd, ret($ret)\n";
        }
    }
    
    my $cmd = "cdbyank -a \'$accession\' $fastaFile.cidx";
    
    if ($SEE) {
        print "CMD: $cmd\n";
    }
    
    my $fastaEntry = `$cmd`;
    if ($?) {
        die "Error, couldn't run cdbyank: $cmd, ret($?)\n";
    }
    
    unless ($fastaEntry) {
        die "Error, no fasta entry retrieved by accession: $accession\n";
    }
    
    return ($fastaEntry);
}


=over 4

=item linearize()

B<Description:> breaks down a fasta sequence into its components 

B<Parameters:> fastaEntry

B<Returns:> (accession, header, linearSequence)

=back

=cut

    ;

sub linearize {
    my ($fastaEntry) = @_;
    
    unless ($fastaEntry =~ /^>/) {
        die "Error, fasta entry lacks expected format starting with header '>' character.\nHere's the entry\n$fastaEntry\n\n";
    }
    
    my @lines = split (/\n/, $fastaEntry);
    my $header = shift @lines;
    my $sequence = join ("", @lines);
    $sequence =~ s/\s+//g;
    
    $header =~ />(\S+)/;
    my $accession = $1;
    
    return ($accession, $header, $sequence);
}



=over 4

=item cdbyank_linear()

B<Description:> same as calling cdbyank (), and chasing it with linearize(), but only the sequence is returned

B<Parameters:> accession, fasta_db

B<Returns:> linearSequence

=back

=cut

    ;


sub cdbyank_linear {
    my ($acc, $fasta_db) = @_;
    
    my $fasta_entry = cdbyank($acc, $fasta_db);
    
    my ($acc2, $header, $genome_seq) = linearize($fasta_entry);

    return ($genome_seq);
}


1; #EOM
    
