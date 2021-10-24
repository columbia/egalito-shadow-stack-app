#!/usr/bin/perl
my $func = $ARGV[0];
while(<STDIN>) {
    chomp;
    if(/<$func>:/) {$p=1}
    if(/^\s*$/) {$p=0}
    print "$_\n" if $p
}
