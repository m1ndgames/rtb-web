#!/usr/bin/perl
use strict;
use warnings;

my $sshuser = 'sc2';
my $remote_host = $ARGV[0];
my @bots = ($ARGV[1], $ARGV[2]);;

foreach (@bots) {
	my $arenapath = "/home/sc2/arena_ladder/bots/$_/data/";
	my $ladderpath = "/home/aiarena/rtb-web/botdata/$_/data/";

	system("mkdir -p $ladderpath");
	system("ssh sc2\@ladder mkdir -p $arenapath");

	chomp(my $rsyncbin = `which rsync`);

        print("Syncing Data to Bot\n");
	system("$rsyncbin -auz $ladderpath $sshuser\@$remote_host:$arenapath");
}
