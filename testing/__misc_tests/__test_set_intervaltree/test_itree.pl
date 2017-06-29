#!/usr/bin/env perl

@INC = (); # clear lib path
use lib ("../../../PerlLib/");
use Set::IntervalTree;

my $tree = Set::IntervalTree->new;
$tree->insert("ID1",100,200);
$tree->insert(2,50,100);
$tree->insert({id=>3},520,700);
$tree->insert("whatever",1000,1100);

my $results = $tree->fetch(400,800);
print scalar(@$results)." intervals found: @$results\n";

