package FusionEM;

use strict;
use warnings;
use Carp;
use Data::Dumper;


our $DEBUG = 0;

####
sub new {
    my ($packagename) = shift;
    
    my $self = { 
        fusions => [],
        
        read_weights => {}, 
    
        _fusion_name_to_fusion_obj => {},
    };


    bless($self, $packagename);

    return($self);
}

####
sub add_fusion_transcript {
    my ($self, $fusion_name, $junction_reads_aref, $spanning_frags_aref) = @_;
    
    my $fusion_transcript = Fusion_transcript->new($fusion_name, $junction_reads_aref, $spanning_frags_aref);

    push (@{$self->{fusions}}, $fusion_transcript);

    $self->{_fusion_name_to_fusion_obj}->{$fusion_name} = $fusion_transcript;

    return;
    
}

####
sub get_fusion_transcripts {
    my ($self) = @_;
    return(@{$self->{fusions}});
}

####
sub get_fusion_transcript {
    my ($self, $fusion_name) = @_;

    my $fusion_obj = $self->{_fusion_name_to_fusion_obj}->{$fusion_name} || confess "Error, no fusion obj found for $fusion_name";
    return($fusion_obj);
}


####
sub run {
    my $self = shift;

    my %read_to_compatibility_class;

    my @fusion_transcripts = $self->get_fusion_transcripts();
    foreach my $fusion (@fusion_transcripts) {
        
        my $fusion_name = $fusion->get_fusion_name();

        foreach my $readname ($fusion->get_junction_reads(), $fusion->get_spanning_frags()) {
            
            $read_to_compatibility_class{$readname}->{$fusion_name} = 1;
        }
    }
    
    my $TRANS_SEP_TOKEN = "--SEP--";
    ## define compatibility classes
    my %compatibility_class_counter;
    my %compatibility_class_to_readnames;
    foreach my $readname (keys %read_to_compatibility_class) {
        my $compatibility_class_href = $read_to_compatibility_class{$readname};
        
        my @compatible_transcripts = keys %$compatibility_class_href;
        
        ## Defining the compatibility class name here.
        my $compatibility_class = join($TRANS_SEP_TOKEN, sort @compatible_transcripts);
        
        $compatibility_class_counter{$compatibility_class}++;
        
        push(@{$compatibility_class_to_readnames{$compatibility_class}}, $readname);
    }
    
    
    ## estimate expression of fusion transcript
    
    ## first round of EM for initialization.
    ## start with initial estimate of equivalence contribution to transcripts of 1/n for n transcripts in equiv class.
    my %fusion_isoform_counts;
    my $total_counts = 0;
    for my $compat_class (keys %compatibility_class_counter) {
        my $count = $compatibility_class_counter{$compat_class};
        $total_counts += $count;
        my @transcripts = split($TRANS_SEP_TOKEN, $compat_class);
        my $num_trans = scalar(@transcripts);
        foreach my $isoform (@transcripts) {
            $fusion_isoform_counts{$isoform} += $count/$num_trans;
        }
    }
    
    my %fusion_isoform_expr;
    foreach my $isoform (keys %fusion_isoform_counts) {
        my $count = $fusion_isoform_counts{$isoform};
        my $fraction = $count/$total_counts;
        $fusion_isoform_expr{$isoform} = $fraction;
    }
    
    if ($DEBUG) { print STDERR Dumper(\%fusion_isoform_expr); }

    ## compute likelihood.

    ## formula from kallisto paper:
    ## 
    ##   L ~ prod_e_E ( sum_t_e )^c_e
    ##
    ##  let's put it in a log likelihood form to avoid underflow
    ## 
    ##  log(L) ~ sum_e_E ( c_e * log(sum_t_e) )

    my $loglikelihood = 0;
    for my $compat_class (keys %compatibility_class_counter) {
        my $compat_class_count = $compatibility_class_counter{$compat_class};
        
        my @transcripts = split($TRANS_SEP_TOKEN, $compat_class);
        
        my $sum_iso_expr = 0;
        foreach my $trans (@transcripts) {
            $sum_iso_expr += $fusion_isoform_expr{$trans};
        }
        $loglikelihood += $compat_class_count * log($sum_iso_expr);
    }
    printf STDERR ("EM: Starting log likelihood: %f\n", $loglikelihood); 
    
    my $MAX_ROUNDS = 1000;
    my $round = 0;
    while ($round <= $MAX_ROUNDS) {
        $round++;
        
        my $prev_loglikelihood = $loglikelihood;
        
        ## Assign counts according to relative expression of isoforms they correspond to.
        %fusion_isoform_counts= (); # reinit
        
        for my $compat_class (keys %compatibility_class_counter) {
            my $count = $compatibility_class_counter{$compat_class};

            my @transcripts = split($TRANS_SEP_TOKEN, $compat_class);
            my $sum_iso_expr = 0;
            foreach my $trans (@transcripts) {
                $sum_iso_expr += $fusion_isoform_expr{$trans};
            }
            
            foreach my $isoform (@transcripts) {
                $fusion_isoform_counts{$isoform} += $count * ($fusion_isoform_expr{$isoform} / $sum_iso_expr);
            }
        }
        
        ## reassess transcript expression values.
        %fusion_isoform_expr = (); # reinit;
        foreach my $isoform (keys %fusion_isoform_counts) {
            my $count = $fusion_isoform_counts{$isoform};
            my $fraction = $count/$total_counts;
            $fusion_isoform_expr{$isoform} = $fraction;
        }
        
        if ($DEBUG) { print STDERR Dumper(\%fusion_isoform_expr); }
        
        $loglikelihood = 0;
        for my $compat_class (keys %compatibility_class_counter) {
            my $compat_class_count = $compatibility_class_counter{$compat_class};
            
            my @transcripts = split($TRANS_SEP_TOKEN, $compat_class);
            
            my $sum_iso_expr = 0;
            foreach my $trans (@transcripts) {
                $sum_iso_expr += $fusion_isoform_expr{$trans};
            }
            $loglikelihood += $compat_class_count * log($sum_iso_expr);
        }
        printf STDERR ("EM: Round [$round] log likelihood: %f\n", $loglikelihood); 
        
        
        if ($loglikelihood - $prev_loglikelihood < 1e-4) { 
            printf STDERR ("EM: Stopping iterations at round $round due to insufficient improvement in likelihood.\n");
            last;
        }
        
    }
    
    # fractionally assign reads according to fusion expression estimates.
    # go through each compatibility class
    
    
    foreach my $compatibility_class (keys %compatibility_class_counter) {
        
        my @fusion_transcript_names = split($TRANS_SEP_TOKEN, $compatibility_class);
        
        my $sum_iso_expr = 0;
        foreach my $trans (@fusion_transcript_names) {
            $sum_iso_expr += $fusion_isoform_expr{$trans};
        }
        my %fusion_trans_rel_expr;
        foreach my $trans (@fusion_transcript_names) {
            $fusion_trans_rel_expr{$trans} = $fusion_isoform_expr{$trans} / $sum_iso_expr;
        }
                
        my @readnames = @{$compatibility_class_to_readnames{$compatibility_class}};
        
        foreach my $readname (@readnames) {
            foreach my $trans (@fusion_transcript_names) {
                
                my $rel_expr = $fusion_trans_rel_expr{$trans};
                
                my $fusion_obj = $self->get_fusion_transcript($trans);
                $fusion_obj->add_read_support_value($readname, $rel_expr);
            }
        }
    }
    
        
}

####
sub get_fusion_estimated_J_S {
    my ($self, $fusion_name) = @_;

    my $fusion_obj = $self->get_fusion_transcript($fusion_name);
    
    return($fusion_obj->{est_J}, $fusion_obj->{est_S});
}



##########################
package Fusion_transcript;

use strict;
use warnings;
use Carp;

####
sub new {
    my ($packagename) = shift;
    my ($fusion_name, $junction_reads_aref, $spanning_frags_aref) = @_;

    my $self = { 
        
        fusion_name => $fusion_name,
        
        junction_reads => {},  # readname => fractional assignment
        spanning_frags => {},
        
        est_J => 0,
        est_S => 0,
    };
    
    ## init reads 
    foreach my $junction_read (@$junction_reads_aref) {
        $self->{junction_reads}->{$junction_read} = 0;
    }
    
    foreach my $spanning_frag (@$spanning_frags_aref) {
        $self->{spanning_frags}->{$spanning_frag} = 0;
    }
    

    bless($self, $packagename);

    return($self);
}

####
sub add_read_support_value {
    my ($self, $readname, $value) = @_;

    if (exists $self->{junction_reads}->{$readname}) {
        $self->{est_J} += $value;
    }
    elsif (exists $self->{spanning_frags}->{$readname}) {
        $self->{est_S} += $value;
    }
    else {
        confess "Error, not finding readname $readname stored as J or S for fusion $self->{fusion_name} ";
    }
    
    return;
}


####
sub get_fusion_name {
    my $self = shift;
    return($self->{fusion_name});
}


####
sub get_junction_reads {
    my $self = shift;
    return(keys %{$self->{junction_reads}});
}

####
sub get_spanning_frags {
    my $self = shift;
    return(keys %{$self->{spanning_frags}});
}

1; #EOM

