#!/usr/bin/perl
use strict;
use warnings;

my $sshuser = 'sc2';
my $remote_host = $ARGV[0];
my @bots = ($ARGV[1], $ARGV[2]);;

foreach (@bots) {
	my $arenapath = "/home/sc2/arena_ladder/bots/$_/data/";
	my $ladderpath = "/home/aiarena/rtb-web/botdata/$_/data/";

	chomp(my $rsyncbin = `which rsync`);

	system("$rsyncbin -a $ladderpath $sshuser\@$remote_host:$arenapath");
}
