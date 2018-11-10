#!/usr/bin/perl
use strict;
use Chart::Clicker;
use Chart::Clicker::Axis::DateTime;
use Chart::Clicker::Data::DataSet;
use Chart::Clicker::Data::Series;
use Chart::Clicker::Renderer::Area;
use DBI;
use Data::Dumper;
chdir("/home/aiarena/rtb-web");

my $database = 'aiarena_db_1';
my $hostname = 'localhost';
my $port = '3306';
my $user = 'aiarena';
my $pass = 'nb89un8bgh978gh95';

chdir('/home/aiarena/rtb-web/');

my $dsn = "DBI:mysql:database=$database;host=$hostname;port=$port";
my $dbh = DBI->connect($dsn, $user, $pass);

# Get the Botlist
my $sth = $dbh->prepare('SELECT name FROM bots',);
$sth->execute();
while (my $ref = $sth->fetchrow_hashref()) {
	my $bot =  $ref->{'name'};
	&getdata($bot);
}
$sth->finish;

# Read the ELO History of each Bot
sub getdata {
	my $name = shift;
	print("Reading elohistory of $name\n");
        my $sth = $dbh->prepare('SELECT elo, date FROM elohistory where name = ?',);
	$sth->execute($name);
	my $elotable = $sth->fetchall_arrayref({});

	&createchart($name,$elotable);
}

# Create a chart for each Bot
sub createchart {
	my $name = shift;
	my $history = shift;
	#print Dumper ($history);

	my $cc = Chart::Clicker->new(width => 800, height => 400);

	my @elo;
	my @date;
	foreach (@$history) {
		push (@elo, $_->{'elo'});
                push (@date, $_->{'date'});
	}

	my $series1 = Chart::Clicker::Data::Series->new(
                name   => 'ELO',
		values => [@elo],
		keys  => [@date]
	);

	my $ds = Chart::Clicker::Data::DataSet->new(series => [ $series1 ]);

	$cc->add_to_datasets($ds);

	my $def = $cc->get_context('default');

	my $dtaxis = Chart::Clicker::Axis::DateTime->new(
		format => '%m/%d',
		position => 'bottom',
		orientation => 'horizontal'
	);

	$def->domain_axis($dtaxis);
	$def->range_axis->brush->width(1);
	$def->domain_axis->brush->width(1);
	$def->range_axis->show_ticks(1);
	$def->domain_axis->show_ticks(1);

	$cc->border->width(0);
	$cc->background_color(
		Graphics::Color::RGB->new(red => .95, green => .94, blue => .92)
	);

	my $orange = Graphics::Color::RGB->new(
		red => .88, green => .48, blue => .09, alpha => 1
	);

	$cc->color_allocator->colors([ $orange ]);
	$def->domain_axis->tick_label_angle(0.785398163);
	$def->range_axis->label_font->family('Hoefler Text');
	$def->range_axis->tick_font->family('Hoefler Text');
	$def->domain_axis->tick_font->family('Hoefler Text');
	$def->domain_axis->label_font->family('Hoefler Text');
	$cc->plot->grid->background_color->alpha(0);
	$def->renderer(Chart::Clicker::Renderer::Area->new(opacity => .50));
	$def->renderer->brush->width(2);
	$cc->legend->font->family('Hoefler Text');

        $cc->legend->visible(0);
	$cc->write_output("./public/charts/$name.png");
}
