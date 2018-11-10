#!/usr/bin/perl
use strict;
use warnings;

my $sshuser = 'sc2';
my $remote_host = $ARGV[0];
my @bots = ($ARGV[1], $ARGV[2]);;

foreach (@bots) {
	# Arena = Service running the games
	my $arenapath = "/home/sc2/arena_ladder/bots/$_/data/";
	my $arenastderrpath = "/home/sc2/arena_ladder/bots/$_/stderr.log";

	# Ladder = Storage
	my $ladderpath = "/home/aiarena/rtb-web/botdata/$_/data/";
	my $ladderstderrpath = "/home/aiarena/rtb-web/botdata/$_/stderr.log";

	system("mkdir -p /home/aiarena/rtb-web/botdata/$_/data/");

	chomp(my $rsyncbin = `which rsync`);

	print("Syncing Data from Bot\n");
	system("$rsyncbin -auz $sshuser\@$remote_host:$arenapath $ladderpath &");
	system("$rsyncbin -auz $sshuser\@$remote_host:$arenastderrpath $ladderstderrpath");
}
