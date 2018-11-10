package RTB::Web;
use Dancer2;
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::Database;
use Dancer2::Plugin::Passphrase;
use Dancer2::Template::TemplateToolkit;
use Dancer2::Session::Memcached;
use Template;
use VT::API;
use Data::Dumper;
use POSIX qw(strftime);
#use File::Slurp;
use DateTime;
use Array::Shuffle qw(shuffle_array);
use MIME::Lite;

# Defines #############################################################################
set behind_proxy => true;
set no_default_pages => true;
our $VERSION = '0.1';
my $vtapi = VT::API->new(key => '1c55d0f05c41f83e9897c5964324b9a8d191b7fc35bd30c0f4d26ecbaf329700');
my $apikey = 'g97nb8n832x7bzu38z3%C3%83%C2%9F95964324b9a8d191b7fc35bd30c0f4d26ecbaf329700';

# Subs ###############################################################################
sub login_page_handler {
    template 'login';
}

sub permission_denied_page_handler {
    template 'denied';
}

sub sendcrashmail {
    my $botname = shift;
    my $sth = database->prepare(
        'SELECT author_name FROM bots WHERE name = ?',
    );
    $sth->execute($botname);
    my @author = $sth->fetchrow_array;

    my $sth2 = database->prepare(
        'SELECT email FROM users WHERE username = ?',
    );
    $sth2->execute($author[0]);
    my @author_email = $sth2->fetchrow_array;

    my $msg = MIME::Lite->new(
    	From    => 'ladder@ai-arena.net',
    	To      => $author_email[0],
    	Cc      => 'florian.luettgens+botcrash@gmail.com',
    	Subject => 'Your Bot has crashed',
    	Type    => 'TEXT',
	Data     => "Please find attached stderr.log"
    );

    $msg->attach(
    	Type     => 'TEXT',
    	Path     => "botdata/$botname/stderr.log",
        Filename => 'stderr.log',
    );

    $msg->send;
}

# Hooks ###############################################################################
hook 'database_connection_lost' => sub {
    print "Starting up\n";
};

# Get #################################################################################
get '/' => sub {
    template 'index' => { 'title' => 'AI Arena' };
};

get '/api/results' => sub {
    my $sth = database->prepare(
        'SELECT * FROM results order by id desc limit 100',
    );
    $sth->execute();
    my $results = $sth->fetchall_arrayref({});

    my $json = JSON->new->allow_nonref;
    my $pretty_json = $json->pretty->encode( $results );
    return($pretty_json);
};

get '/api/bots' => sub {
    my $sth = database->prepare(
        'SELECT * FROM bots',
    );
    $sth->execute();
    my $results = $sth->fetchall_arrayref({});

    my $json = JSON->new->allow_nonref;
    my $pretty_json = $json->pretty->encode( $results );
    return($pretty_json);
};

sub creatematchqueue {
    my $sth = database->prepare(
        'SELECT * FROM bots where active = 1',
    );
    $sth->execute();
    my $bots = $sth->fetchall_arrayref({});

    my @botlist;
    foreach (@{$bots}) {
        push (@botlist, $_->{'name'});
    }
    shuffle_array(@botlist);

    my @matches;
    foreach (@botlist) {
        my $bot = $_;
        foreach (@botlist) {
            if ($bot eq $_) {
                next;
            } else {
		my $match = {'bot1' => $bot, 'bot2' => $_};
                push (@matches, $match);
            }
        }
    }
    my $json = JSON->new->allow_nonref;
    my $pretty_json = $json->pretty->encode( \@matches );
    open my $fh, ">", "matchqueue.json";
    print $fh ($pretty_json);
    close $fh;
}

get '/api/nextmatch' => sub {
    my $params = params;
    my $client_key = $params->{'apikey'};
    if (!$client_key) {
	print("Showing nextmatch without API key\n");
        $client_key = "nope123";
    }

    if (!-e 'matchqueue.json') {
        &creatematchqueue();
    }

    # read the match queue
    my $injson;
    {
        local $/;
        open my $fh, "<", "matchqueue.json";
        $injson = <$fh>;
        close $fh;
    }
    my $in_json = decode_json($injson);

    # find 1st match bots
    my @bots = @{$in_json};
    my @newbots;
    my $bot1;
    my $bot2;
    foreach (@bots) {
        if (!$_->{'bot1'} and !$_->{'bot2'}) {
            next;
        }
        $bot1 = $_->{'bot1'};
        $bot2 = $_->{'bot2'};
        if ($client_key eq $apikey) {
            print("Got API key - Removing $_->{'bot1'} and $_->{'bot2'}\n");
            $_->{'bot1'} = undef;
            $_->{'bot2'} = undef;
        

            foreach (@bots) {
                if ($_->{'bot1'} and $_->{'bot2'}) {
                    push (@newbots, $_);
                }
            }    
        }
        last;
    }

    if ($client_key eq $apikey) {
        my $matchcount = scalar @newbots;
        print("Matches in Queue: $matchcount\n");

        # write file
        open my $fh, ">", "matchqueue.json";
        my $filejson = JSON->new->allow_nonref;
        print $fh $filejson->pretty->encode( \@newbots );
        close $fh;

        if ($matchcount <= 1) {
            print("MatchQueue is empty - recreating\n");
            &creatematchqueue();
        }
        &syncdata2bot('ladder', $bot1, $bot2);
    }    

    # get bot data from db
    my $sth = database->prepare(
        'SELECT * FROM bots where name = ? or name = ?',
    );
    $sth->execute($bot1, $bot2);

    my $bots = $sth->fetchall_arrayref({});
    my $json = JSON->new->allow_nonref;
    my $pretty_json = $json->pretty->encode( $bots );
    return($pretty_json);
};

get '/upload' => require_login sub {
    template 'upload';
};

get '/uploadsuccess' => require_login sub {
    template 'uploadsuccess';
};

get '/register' => sub {
    template 'register';
};

get '/contribute' => sub {
    template 'contribute';
};

get '/rules' => sub {
    template 'rules';
};

get '/stream' => sub {
    template 'stream';
};

get '/results' => sub {
    my $sth = database->prepare(
        'SELECT * FROM results ORDER BY id DESC LIMIT 35',
    );
    $sth->execute();
    my $results = $sth->fetchall_arrayref({});

    my $sth2 = database->prepare(
        'SELECT * FROM results WHERE date > DATE_SUB(NOW(), INTERVAL 24 HOUR)',
    );
    $sth2->execute();
    my $results_24h = $sth2->fetchall_arrayref({});
    my $results_24h_count = scalar @{ $results_24h };

    # read the match queue
    my $matchqueuefile;
    {
        local $/;
        open my $fh, "<", "matchqueue.json";
        $matchqueuefile = <$fh>;
        close $fh;
    }
    my $matchqueue = decode_json($matchqueuefile);
    my $queuesize = scalar @{ $matchqueue };
    if (!$queuesize) {
	$queuesize = 0;
    }

    template 'results' => { results => $results, matchcount => $results_24h_count, queuesize => $queuesize }
};

get '/ranking' => sub {
    my $sth = database->prepare(
        'SELECT * FROM bots where active = 1',
    );
    $sth->execute();
    my $bots = $sth->fetchall_arrayref({});

    template 'ranking' => { bots => $bots}
};

get '/bot/:name' => sub {
    my $name = route_parameters->get('name');
    my $sth = database->prepare(
        'SELECT * FROM bots where name = ?',
    );
    $sth->execute($name);
    my $bot_table = $sth->fetchall_arrayref({});

    my $sth2 = database->prepare(
        'SELECT * FROM results where bot_a = ? OR bot_b = ? order by id desc limit 50',
    );
    $sth2->execute($name, $name);
    my $results_table = $sth2->fetchall_arrayref({});

    template 'bot' => { name=>$name, bots=> $bot_table, results=> $results_table };
};

get '/maps' => sub {
    template 'maps';
};

get '/maps/arena_1' => sub {
    template 'maps_arena_1';
};

get '/maps/arena_2' => sub {
    template 'maps_arena_2';
};

get '/maps/arena_3' => sub {
    template 'maps_arena_3';
};

get '/login' => sub {
    template 'login';
};

any ['get', 'post'] => '/profile' => require_login sub {
    if ( request->method() eq "POST" ) {
      my $user = logged_in_user;
      my $action = body_parameters->get('action');
      my $sth = database->prepare(
          'SELECT id FROM users WHERE username = ?',
      );
      $sth->execute($user->{username});
      my @author_id = $sth->fetchrow_array;
      my $botname = body_parameters->get('botname');
      my $sql2 = 'update bots set active = ? where author_id = ? and name = ?';
      my $sth2 = database->prepare($sql2) or die database->errstr;

      if ($action eq 'activate') {
        $sth2->execute(1, $author_id[0], $botname) or die $sth2->errstr;
      } else {
        $sth2->execute(0, $author_id[0], $botname) or die $sth2->errstr;
      }

      redirect '/profile';

    } else {
      my $user = logged_in_user;
      my $sth = database->prepare(
          'SELECT id FROM users WHERE username = ?',
      );
      $sth->execute($user->{username});
      my @author_id = $sth->fetchrow_array;

      my $sth2 = database->prepare(
          'SELECT * FROM bots WHERE author_id = ?',
      );
      $sth2->execute($author_id[0]);
      my $bots = $sth2->fetchall_arrayref({});

      template 'profile' => { bots => $bots, user => $user->{username} }
    }
};

# Post ################################################################################
post '/download' => sub {
    my $params = params;
    my $client_key = $params->{'apikey'};
    my $bot = $params->{'bot'};

    my $sth = database->prepare(
        'SELECT filename FROM bots WHERE name = ?',
    );
    $sth->execute($bot);
    my @botfilename = $sth->fetchrow_array;
    chomp(my $dir = path(config->{appdir}, 'botuploads'));
    my $botfile = "$dir/$botfilename[0]";

    if ($client_key eq $apikey) {
        return send_file($botfile, system_path => 1);
    } else {
	return "nope";
    }
};

post '/downloadlogfile' => sub {
    my $params = params;
    my $requester = $params->{'requester'};
    my $bot = $params->{'botname'};
    my $sth = database->prepare(
        'SELECT * FROM bots WHERE author_name = ? and name = ?',
    );
    $sth->execute($requester, $bot);
    my @author = $sth->fetchrow_array;
    if (!$author[0]) {
        return;
    }

    my $authorname = $author[1];

    if ($authorname eq $requester) {
        chomp(my $dir = path(config->{appdir}, "botdata/$bot"));
        my $botfile = "$dir/stderr.log";
        return send_file($botfile, system_path => 1);
    }
};

post '/downloaddata' => sub {
    my $params = params;
    my $requester = $params->{'requester'};
    my $bot = $params->{'botname'};
    my $sth = database->prepare(
        'SELECT * FROM bots WHERE author_name = ? and name = ?',
    );
    $sth->execute($requester, $bot);
    my @author = $sth->fetchrow_array;
    if (!$author[0]) {
        return;
    }

    my $authorname = $author[1];

    if ($authorname eq $requester) {
        chomp(my $dir = path(config->{appdir}, "botdata/$bot"));
	chomp(my $zip = `which zip`);
        chdir("$dir");
        system("$zip -r /tmp/$bot\_data.zip data/");
        chdir('/home/aiarena/rtb-web');
        my $datafile = "/tmp/$bot\_data.zip";
        return send_file($datafile, system_path => 1);
	unlink($datafile);
    }
};

post '/api/results' => sub {
    my $params = params;
    my $client_key = $params->{'apikey'};
    my $bot_a = $params->{'bot_a'};
    my $bot_b = $params->{'bot_b'};
    my $result = $params->{'result'};
    my $winner = $params->{'winner'};
    my $gametime = $params->{'gametime'};
    my $mapname = $params->{'map'};
    my $replayname = $params->{'replayname'};

    if ($client_key eq $apikey) {
        my $sth = database->prepare(
    	    'SELECT elo FROM bots WHERE name = ?',
        );
        $sth->execute($bot_a);
        my @bot_a_elo = $sth->fetchrow_array;

        my $sth2 = database->prepare(
            'SELECT elo FROM bots WHERE name = ?',
        );
        $sth2->execute($bot_b);
        my @bot_b_elo = $sth2->fetchrow_array;

        my $result_a;
        my $result_b;

	if ($result eq 'Player1Win') {
	    ($result_a, $result_b) = &elo($bot_a_elo[0], $bot_b_elo[0], 1.0);
        }

	if ($result eq 'Player2Win') {
	    ($result_a, $result_b) = &elo($bot_a_elo[0], $bot_b_elo[0], 0.0);
        }

	if (($result eq 'GameTimeout') or ($result eq 'Tie')) {
            #$result_a = &elo($bot_a_elo[0], $bot_b_elo[0], 0.5);
            #$result_b = &elo($bot_b_elo[0], $bot_a_elo[0], 0.5);
	    ($result_a, $result_b) = &elo($bot_a_elo[0], $bot_b_elo[0], 0.5);
        }

	if ($result eq 'Player1Crash') {
            $result_b = $bot_b_elo[0] + 5;
            $result_a = $bot_a_elo[0] - 10;
            my $sql = 'update bots set active = ? where name = ?';
            my $sth = database->prepare($sql) or die database->errstr;
            $sth->execute(0, $bot_a) or die $sth->errstr;
	    unlink('matchqueue.json');
	    &sendcrashmail($bot_a);
        }

	if ($result eq 'Player2Crash') {
            $result_a = $bot_a_elo[0] + 5;
            $result_b = $bot_b_elo[0] - 10;

	    my $sql = 'update bots set active = ? where name = ?';
      	    my $sth = database->prepare($sql) or die database->errstr;
            $sth->execute(0, $bot_b) or die $sth->errstr;
	    unlink('matchqueue.json');
	    &sendcrashmail($bot_b);
        }

	my $elo_a_change = $result_a - $bot_a_elo[0];
        my $elo_b_change = $result_b - $bot_b_elo[0];

        my $sql3 = 'insert into results (bot_a, bot_b, result, elochange_bot_a, elochange_bot_b, mapname, gametime, winner, replayname) values (?, ?, ?, ?, ?, ?, ?, ?, ?)';
        my $sth3 = database->prepare($sql3) or die database->errstr;
        $sth3->execute($bot_a, $bot_b, $result, $elo_a_change, $elo_b_change, $mapname, $gametime, $winner, $replayname) or die $sth3->errstr;

        my $sql4 = 'update bots set elo = ? where name = ?';
        my $sth4 = database->prepare($sql4) or die database->errstr;
        $sth4->execute($result_a, $bot_a) or die $sth4->errstr;

        my $sql5 = 'update bots set elo = ? where name = ?';
        my $sth5 = database->prepare($sql5) or die database->errstr;
        $sth5->execute($result_b, $bot_b) or die $sth5->errstr;

	my $dt = time;
	my $sql6 = 'insert into elohistory (name, elo, date) values (?, ?, ?)';
        my $sth6 = database->prepare($sql6) or die database->errstr;
	$sth6->execute($bot_a, $result_a, $dt) or die $sth6->errstr;

        my $sql7 = 'insert into elohistory (name, elo, date) values (?, ?, ?)';
        my $sth7 = database->prepare($sql7) or die database->errstr;
        $sth7->execute($bot_b, $result_b, $dt) or die $sth7->errstr;

        #TODO: Get server ip
        &syncdatafrombot('ladder', $bot_a, $bot_b);
    } else {
        return "nope";
    }
};

sub syncdatafrombot {
    my $server = shift;
    my $bot_a = shift;
    my $bot_b = shift;
    chomp(my $perl = `which perl`);
    my $fetch = "$perl ./syncfrombot.pl $server $bot_a $bot_b &";
    system($fetch);
}

sub syncdata2bot {
    my $server = shift;
    my $bot_a = shift;
    my $bot_b = shift;
    chomp(my $perl = `which perl`);
    my $push = "$perl ./sync2bot.pl $server $bot_a $bot_b &";
    system($push);
}

post '/api/uploadreplay' => sub {
    my $client_key = params->{'apikey'};
    my $filename = params->{'filename'};
    my $replay = request->upload('file');

    print("Saving $filename to ./public/replays/$filename\n");

    if ($client_key eq $apikey) {
        my $path = "./public/replays/$filename";
	$replay->copy_to($path);
    } else {
         return "nope";
    }
};

sub expected_win_rate  {
	my $rating1 = shift;
	my $rating2 = shift;
	return 1.0 / (1.0 + 10.0 ** (($rating2 - $rating1) / 400.0));
}

sub elo {
	my $rating1 = shift;
	my $rating2 = shift;
	my $actual = shift;
	my $elo_k = 32;

	my $delta = $elo_k * ($actual - &expected_win_rate($rating1, $rating2));
	return ($rating1 + $delta, $rating2 - $delta);
}

post '/register' => sub {
    my $username = body_parameters->get('username');
    my $password = body_parameters->get('password');
    my $email = body_parameters->get('email');

    my $sql = 'insert into users (username, password, email) values (?, ?, ?)';
    my $sth = database->prepare($sql) or die database->errstr;
    $sth->execute($username, $password, $email) or die $sth->errstr;

    template registered => { success => 1 };
};

post '/upload' => require_login sub {
    my $user = logged_in_user;
    my $botname = params->{botname};
    my $bottype = params->{bottype};
    my $data = request->upload('file');
    my $path;
 
    my $dir = path(config->{appdir}, 'botuploads');
    mkdir $dir if not -e $dir;

    my $filetype = $data->type;
    my $filesize = $data->size;
    my $maxfilesize = 10000000;
    my $uploadname = $data->{filename};
    my $extension;
    if ($uploadname =~ /.+\.(.+)/) {
        $extension = $1;
    }

    if ($botname !~ /^\w+$/) {
	return "Name can only be alphanumeric + underscores";
    }

    if ($filesize > $maxfilesize) {
        return "Upload failed! - $filetype - $filesize - exceeds 10mb";
    }

    if ($extension ne 'zip') {
        return "Upload failed! - please use zip to archive and re-upload";
    }

    my $filename = "$user->{username}_$botname.$extension";
    $path = path($dir, "$user->{username}_$botname.$extension");
    $data->copy_to($path);
    chomp(my $filehash = `md5sum $path | awk \'\{ print \$1 \}\'`);

    # Virus scan
    #my $virus_response = $vtapi->scan_file($path);

    # Write to db
    my $sth = database->prepare(
        'SELECT id FROM users WHERE username = ?',
    );
    $sth->execute($user->{username});
    my @author_id = $sth->fetchrow_array;

    # Check if bot has been uploaded before
    my $sth2 = database->prepare(
        'SELECT * FROM bots WHERE author_id = ? AND name = ?',
    );
    $sth2->execute($author_id[0],$botname);
    my @botlist = $sth2->fetchrow_array;
    my %bots = map { $_ => 1 } @botlist;

    # Bot already exists
    if(exists($bots{$botname})) {
        my $sql3 = 'update bots set last_upload_date = ? , filesize = ? , md5hash = ?, bottype = ? where author_id = ? and name = ?';
        my $sth3 = database->prepare($sql3) or die database->errstr;
        my $now = strftime "%Y-%m-%d %H:%M:%S", localtime;
        $sth3->execute($now, $filesize, $filehash, $bottype, $author_id[0], $botname) or die $sth3->errstr;
    # Its new
    } else {
        my $sql3 = 'insert into bots (author_id, author_name, name, filename, filesize, md5hash, bottype) values (?, ?, ?, ?, ?, ?, ?)';
        my $sth3 = database->prepare($sql3) or die database->errstr;
        $sth3->execute($author_id[0], $user->{username}, $botname, $filename, $filesize, $filehash, $bottype) or die $sth3->errstr;
    }

    # TODO: display error on upload page instead of return
    #template uploadresult => { success => 1 };
    template 'uploadsuccess';
};

post '/login' => sub {
    my ($success,$realm) = authenticate_user(
        params->{username}, params->{password}
    );

    if ($success) {
        session logged_in_user => params->{username};
        session 'logged_in' => true;
        session logged_in_user_realm => $realm;
        redirect '/';
    } else {
        redirect '/login';
    }
};

# ANY #################################################################################
any '/logout' => sub {
    context->destroy_session;
    redirect '/';
};

# EOF #################################################################################
true;
package RTB::Web;
