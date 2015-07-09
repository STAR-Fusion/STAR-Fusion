#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use Getopt::Long qw(:config no_ignore_case bundling pass_through);

use FindBin;
use lib ("$FindBin::Bin/../../PerlLib");
use Fasta_reader;
use Overlap_piler;
use Nuc_translator;

my $max_intron_length = 500;
my $genome_flank_size = 1000;
my $min_gene_length = 100;


my $usage = <<__EOUSAGE__;

###############################################################################################
#
#  Required:
#
#  --gtf <string>                   genome annotation in gtf format
#
#  --genome_fa <string>             genome sequence in fasta format
#
# Optional:
#
#  --shrink_introns
#
#  --max_intron_length <int>        default: $max_intron_length  (only when --shrink_introns used)
#
#  --genome_flank <int>             amt. of genomic sequence to extract flanking each gene (default: $genome_flank_size)
#
#  --out_prefix <string>            output prefix for output files (gtf and fasta) default: geneMergeContig.\${process_id}
#
#  --min_gene_length <int>          default: $min_gene_length
#
###############################################################################################


__EOUSAGE__

    ;

my $help_flag;

my $gtf_file;
my $genome_fasta_file;
my $out_prefix = "geneContigs.$$";
my $shrink_introns_flag = 0;

&GetOptions ( 'h' => \$help_flag,
              
              'gtf=s' => \$gtf_file,
              'genome_fa=s' => \$genome_fasta_file,

              'shrink_introns' => \$shrink_introns_flag,
              'max_intron_length=i' => \$max_intron_length,
              'genome_flank=i' => \$genome_flank_size,
              
              'out_prefix=s' => \$out_prefix,
              
              'min_gene_length=i' => \$min_gene_length,

    );


if ($help_flag) {
    die $usage;
}

unless ($gtf_file && $genome_fasta_file) {
    die $usage;
}

main: {

    print STDERR "-parsing GTF file: $gtf_file\n";
    my %gene_to_gtf = &extract_gene_gtfs($gtf_file);
    
    print STDERR "-parsing genome sequence from $genome_fasta_file\n";
    my $fasta_reader = new Fasta_reader($genome_fasta_file);
    my %genome = $fasta_reader->retrieve_all_seqs_hash();
    
    open (my $out_genome_ofh, ">$out_prefix.fa") or die "Error, cannot write to $out_prefix.fa";
    open (my $out_gtf_ofh, ">$out_prefix.gtf") or die "Error, cannot write to $out_prefix.gtf";

    

        
    foreach my $gene_id (keys %gene_to_gtf) {
   
        print STDERR "-processing gene: $gene_id\n";
        
        my $gene_gtf = $gene_to_gtf{$gene_id};

        eval {

            my ($gene_supercontig_gtf, $gene_sequence_region) = &get_gene_contig_gtf($gene_gtf, \%genome);
            
            if ($shrink_introns_flag) {
                ($gene_supercontig_gtf, $gene_sequence_region) = &shrink_introns($gene_supercontig_gtf, $gene_sequence_region, $max_intron_length);
            }

            my $supercontig = $gene_sequence_region;
                        
            if (length($supercontig) >= $min_gene_length) {
                
                $supercontig =~ s/(\S{60})/$1\n/g; # make fasta 
                chomp $supercontig;
                
                print $out_genome_ofh ">$gene_id\n$supercontig\n";

                my $out_gtf = &set_gtf_scaffold_name($gene_id, $gene_supercontig_gtf);
                
                print $out_gtf_ofh $out_gtf;
            }
            else {
                print STDERR "-skipping $gene_id, too short.\n";
            }
        };

        if ($@) {
            print STDERR "$@\n";
        }
    }
    
    
    print STDERR "Done.\n";
    
    close $out_genome_ofh;
    close $out_gtf_ofh;

    exit(0);
    

}

####
sub shrink_introns {
    my ($gene_gtf, $gene_seq_region, $max_intron_length) = @_;

    my @gtf_structs;
    my @gtf_lines = split(/\n/, $gene_gtf);
    foreach my $gtf_line (@gtf_lines) {
        my @x = split(/\t/, $gtf_line);
        push (@gtf_structs, \@x);
    }
    
    @gtf_structs = sort {$a->[3]<=>$b->[3]} @gtf_structs;

    
    ## get exon piles
    my $overlap_piler = new Overlap_piler();
    foreach my $gtf_row_aref (@gtf_structs) {
        
        my $exon_lend = $gtf_row_aref->[3];
        my $exon_rend = $gtf_row_aref->[4];
        $overlap_piler->add_coordSet($gtf_row_aref, $exon_lend, $exon_rend);
    }

    my @piles = $overlap_piler->build_clusters();
    
    my @pile_structs;
    foreach my $pile (@piles) {
        
        my @all_coords;
        foreach my $gtf_row_aref (@$pile) {
            my $lend = $gtf_row_aref->[3];
            my $rend = $gtf_row_aref->[4];
            push (@all_coords, $lend, $rend);
        }
        @all_coords = sort {$a<=>$b} @all_coords;

        my $pile_lend = shift @all_coords;
        my $pile_rend = pop @all_coords;
        
        my $pile_struct = { pile => $pile,
                            pile_lend => $pile_lend,
                            pile_rend => $pile_rend,
                            
                            pile_length => $pile_rend - $pile_lend + 1,

                    
                            new_pile_lend => $pile_lend,
                            new_pile_rend => $pile_rend,
        };
        push (@pile_structs, $pile_struct);
    }
   

    @pile_structs = sort { $a->{pile_lend} <=> $b->{pile_lend} } @pile_structs;

    ## set new pile bounds based on max intron length
    for (my $i = 1; $i <= $#pile_structs; $i++) {
        my $prev_pile_struct = $pile_structs[$i-1];
        my $curr_pile_struct = $pile_structs[$i];

        my $intron_length = $curr_pile_struct->{pile_lend} - $prev_pile_struct->{pile_rend} - 1;
        if ($intron_length > $max_intron_length) {
            $intron_length = $max_intron_length;
        }
        $curr_pile_struct->{new_pile_lend} = $prev_pile_struct->{new_pile_rend} + $intron_length + 1;
        $curr_pile_struct->{new_pile_rend} = $curr_pile_struct->{new_pile_lend} + $curr_pile_struct->{pile_length} - 1;
        
    }

    ## adjust gtf exon coordinates
    
    my $gtf_adj = "";
    my $gene_seq_adj = "";
    
    my $prev_old_pile_rend = 0;
    
    foreach my $pile_struct (@pile_structs) {
        
        my $old_pile_lend = $pile_struct->{pile_lend};
        my $new_pile_lend = $pile_struct->{new_pile_lend};
        my $pile_length = $pile_struct->{pile_length};
        
        my $delta = $old_pile_lend - $new_pile_lend;
        
        ## add intron
        my $intron_len = $old_pile_lend - $prev_old_pile_rend -1;
        my $intron_seq = "";
        if ($prev_old_pile_rend == 0 || $intron_len < $max_intron_length) {
            $intron_seq = substr($gene_seq_region, $prev_old_pile_rend, $intron_len);
        }
        else {
            ## split the difference
            my $left_intron_size = int($max_intron_length/2);
            my $right_intron_size = $max_intron_length - $left_intron_size;
            my $left_intron_seq = substr($gene_seq_region, $prev_old_pile_rend, $left_intron_size);
            my $right_intron_seq = substr($gene_seq_region, $old_pile_lend - 1 - $right_intron_size, $right_intron_size);
            
            $left_intron_seq = &mask_intron('left', $left_intron_seq);
            $right_intron_seq = &mask_intron('right', $right_intron_seq);
            
            $intron_seq = $left_intron_seq . $right_intron_seq;
            
            if (length($intron_seq) != $max_intron_length) {
                die "Error, intron length is off: " . length($intron_seq) . " vs. $max_intron_length (max)";
            }
        }
        $gene_seq_adj .= $intron_seq;

        foreach my $gtf_row_aref (@{$pile_struct->{pile}}) {
            
            $gtf_row_aref->[3] -= $delta;
            $gtf_row_aref->[4] -= $delta;

            $gtf_adj .= join("\t", @$gtf_row_aref) . "\n";
        }

        my $pile_seq = substr($gene_seq_region, $old_pile_lend -1, $pile_length);
        $gene_seq_adj .= $pile_seq;

        $prev_old_pile_rend = $pile_struct->{pile_rend};
        
    }
    
    ## tack on end of sequence
    $gene_seq_adj .= substr($gene_seq_region, $prev_old_pile_rend);
    
    return($gtf_adj, $gene_seq_adj);
}


####
sub mask_intron {
    my ($keep_dir, $intron_seq) = @_;

    my $keep_chars = 10;

    my @chars = split(//, $intron_seq);
    if ($keep_dir eq 'left') {
        for (my $i = $keep_chars; $i <= $#chars; $i++) {
            $chars[$i] = 'N';
        }
    }
    else {
        for (my $i = 0; $i <= $#chars - $keep_chars; $i++) {
            $chars[$i] = 'N';
        }
    }

    my $updated_intron_seq = join("", @chars);
    
    return($updated_intron_seq);
}



    
####
sub set_gtf_scaffold_name {
    my ($scaffold_name, $gtf_text) = @_;

    my $new_gtf = "";
    
    foreach my $line (split(/\n/, $gtf_text)) {
        
        my @x = split(/\t/, $line);
        $x[0] = $scaffold_name;
        
        $x[8] =~ s/transcript_id \"/transcript_id \"$scaffold_name\./;
        $x[8] =~ s/gene_id \"/gene_id \"$scaffold_name\./;
        
        $new_gtf .= join("\t", @x) . "\n";
    }

    return($new_gtf);
}

####
sub get_gene_contig_gtf {
    my ($gene_gtf, $genome_href) = @_;

    
    my ($gene_chr, $gene_lend, $gene_rend, $gene_orient) = &get_gene_span_info($gene_gtf);
    
    my $chr_seq = $genome_href->{$gene_chr} or die "Error, no sequence for chr: $gene_chr";

    my $seq_region = &get_genomic_region_sequence(\$chr_seq,
                                                  $gene_chr, 
                                                  $gene_lend - $genome_flank_size, 
                                                  $gene_rend + $genome_flank_size,
                                                  $gene_orient);

    my $gene_contig_gtf = &transform_gtf_coordinates($gene_lend - $genome_flank_size,
                                                     $gene_gtf,
                                                     length($seq_region),
                                                     $gene_orient);
    
    return($gene_contig_gtf, $seq_region);
    
    
}


#####
sub get_genomic_region_sequence {
    my ($seq_sref, $chr, $lend, $rend, $orient) = @_;

    my $seq_len = $rend - $lend + 1;
    
    my $seq = substr($$seq_sref, $lend-1, $seq_len);
        
    if ($orient eq '-') {
        $seq = &reverse_complement($seq);
    }

    return($seq);
}



####
sub extract_gene_gtfs {
    my ($gtf_file) = @_;

    my %gene_to_gtf;

    open (my $fh, $gtf_file) or die "Error, cannot open file $gtf_file";
    while (<$fh>) {
        chomp;
        if (/^\#/) { next;}
        unless (/\w/) { next; }
        my $line = $_;
        

        my $gene_id = "";
        my $gene_name = "";
        if (/gene_id \"([^\"]+)\"/) {
            $gene_id = $1;
        }
        else {
            die "Error, no gene ID for $_";
        }
        if (/gene_name \"([^\"]+)\"/) {
            $gene_name = $1;
            
            if ($gene_id) {
                $line =~ s/$gene_id/$gene_name\.$gene_id/;
            }
        }
        else {
            $gene_name = $gene_id;
        }
        
        my @x = split(/\t/, $line);
        my $chr = $x[0];
        my $lend = $x[3];
        my $rend = $x[4];
        my $orient = $x[6];
        
        
        ## ensure gene id is unique, since same genes are found on diff chrX and chrY, etc., and gene names arent always unique.
        $gene_id = join("::", $chr, $gene_id, $gene_name) . "::"; # last one ensures we can parse later on and get the last field.
        

        my $orig_info = "$chr,$lend,$rend,$orient";
        $line .= " orig_coord_info \"$orig_info\";\n";
        
        $gene_to_gtf{$gene_id} .= $line;
                
    }
    close $fh;

    return(%gene_to_gtf);
}


####
sub get_gene_span_info {
    my ($gene_gtf_text) = @_;

    my ($chr, $min_lend, $max_rend, $orient);

    my @gtf_lines = split(/\n/, $gene_gtf_text);
    foreach my $line (@gtf_lines) {
        my @x = split(/\t/, $line);
        my $scaffold = $x[0];
        my $lend = $x[3];
        my $rend = $x[4];
        my $strand = $x[6];
        if (defined $chr) {
            ## check to ensure the rest of the info matches up
            if ($chr ne $scaffold) {
                die "Error, chr discrepancy in gtf info: $gene_gtf_text";
            }
            if ($orient ne $strand) {
                die "Error, strand conflict in gtf info: $gene_gtf_text";
            }
            if ($lend < $min_lend) {
                $min_lend = $lend;
            }
            if ($rend > $max_rend) {
                $max_rend = $rend;
            }
            
        }
        else {
            ## init
            ($chr, $min_lend, $max_rend, $orient) = ($scaffold, $lend, $rend, $strand);
        }
    }

    return($chr, $min_lend, $max_rend, $orient);
}

####
sub transform_gtf_coordinates {
    my ($left_reference_pos, $gene_gtf, $seq_length, $gene_orient) = @_;

    my $new_gtf = "";
    
    foreach my $line (split(/\n/, $gene_gtf)) {
        
        my @fields = split(/\t/, $line);
        my ($lend, $rend) = ($fields[3], $fields[4]);
        
        $lend = $lend - $left_reference_pos + 1;
        $rend = $rend - $left_reference_pos + 1;
        
        if ($gene_orient eq '-') {
            # revcomp the coordinates
            $lend = $seq_length - $lend + 1;
            $rend = $seq_length - $rend + 1;
            ($lend, $rend) = sort {$a<=>$b} ($lend, $rend);
        }

        $fields[3] = $lend;
        $fields[4] = $rend;
        $fields[6] = '+';
        
        $new_gtf .= join("\t", @fields) . "\n";
    }
    
    return($new_gtf);

}

####
sub adjust_gtf_coordinates {
    my ($gtf, $adjustment) = @_;

    my $new_gtf = "";
   
    foreach my $line (split(/\n/, $gtf)) {

        my @fields = split(/\t/, $line);
        $fields[3] += $adjustment;
        $fields[4] += $adjustment;

        $new_gtf .= join("\t", @fields) . "\n";
    }

    return($new_gtf);
}

####
sub process_cmd {
    my ($cmd) = @_;

    print STDERR "CMD: $cmd\n";
    my $ret = system($cmd);
    if ($ret) {
        die "Error, CMD: $cmd died with ret $ret";
    }

    return;
}

