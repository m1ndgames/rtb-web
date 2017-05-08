#!/usr/bin/perl
use strict;
use warnings;

my $rsync = `which rsync`;
my $path = '/home/t00r/RTB-Web/botuploads';

opendir my $dir, $path or die "Cannot open directory: $!";
my @files = readdir $dir;
closedir $dir;

foreach (@files) {
    if ($_ =~ /^\./) { next; }
    my $result;
    my $scan = `clamscan --no-summary $path/$_`;
    if ($scan =~ /$path\/$_: (.+)/) {
        $result = $1;
    }

    if ($result ne 'OK') {
        system("echo \"$_ is a Virus!\" >> bottransfer.log");
        system("mv $path/$_ /home/t00r/RTB-Web/honeypot");
    }
}

system("");
