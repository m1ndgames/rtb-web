#!/usr/bin/perl
use strict;
use warnings;
use DBI;
use Data::Dumper;

my $database = 'aiarena';
my $hostname = 'localhost';
my $port = '3306';
my $user = 'aiarena';
my $pass = 'bTs8aum3';

chdir('/home/m1nd/rtb-web/');

my @arcademaps = `ls ./public/dl/maps/arcade`;
my @laddermaps = `ls ./public/dl/maps/ladder`;
my $dsn = "DBI:mysql:database=$database;host=$hostname;port=$port";
my $dbh = DBI->connect($dsn, $user, $pass);

# clear arcade maps
my $sth = $dbh->prepare("TRUNCATE TABLE mappool_arcade");
$sth->execute or die $sth->errstr;

# insert arcade maps
foreach (@arcademaps) {
	chomp(my $mapname = $_);

	if ($mapname =~ /_training/) { next(); }

	my $sql = 'insert into mappool_arcade (name) values (?)';
	my $sth = $dbh->prepare($sql) or die database->errstr;
	$sth->execute($mapname) or die $sth->errstr;
}


# clear ladder maps
$sth = $dbh->prepare("TRUNCATE TABLE mappool_ladder");
$sth->execute or die $sth->errstr;

# insert ladder maps
foreach (@laddermaps) {
        chomp(my $mapname = $_);
        my $sql = 'insert into mappool_ladder (name) values (?)';
        my $sth = $dbh->prepare($sql) or die database->errstr;
        $sth->execute($mapname) or die $sth->errstr;
}
