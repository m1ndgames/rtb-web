#!/usr/bin/perl
use strict;
use warnings;
use Time::Piece;

my $rsync = `which rsync`;
my $uploadpath = '/home/t00r/RTB-Web/botuploads';
my $botpath = '/home/rtb/bots';
my $rtbserver = 'rtb@m1nd.io';
my $sshport = 2222;
my $date = localtime->strftime('%Y-%m-%d_%H:%M');

opendir my $dir, $uploadpath or die "Cannot open directory: $!";
my @files = readdir $dir;
closedir $dir;

foreach (@files) {
    if ($_ =~ /^\./) { next; }
    my $result;
    my $scan = `clamscan --no-summary $uploadpath/$_`;
    if ($scan =~ /$uploadpath\/$_: (.+)/) {
        $result = $1;
    }

    if ($result ne 'OK') {
        system("echo \"$date - $_ is a Virus!\" >> bottransfer.log");
        system("mv $uploadpath/$_ /home/t00r/RTB-Web/honeypot");
    }
}

my @rsync = `$rsync -avz -e \"ssh -p $sshport\" $uploadpath $rtbserver:$botpath`;

foreach (@rsync) {
	if ($_ =~ /^botuploads\/(.+)$/) {
		my $upload = $1;
		$date = localtime->strftime('%Y-%m-%d_%H:%M');
		system("echo \"$date - Uploaded: $upload\" >> bottransfer.log");
	}
}
