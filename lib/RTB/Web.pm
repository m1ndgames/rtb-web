package RTB::Web;
use Dancer2;
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::Database;
use Dancer2::Plugin::Passphrase;
use Dancer2::Template::TemplateToolkit;
use Dancer2::Session::Memcached;
use Template;
use Chess::Elo qw(:all);
use VT::API;
use Data::Dumper;
use POSIX qw(strftime);

# Defines #############################################################################
set behind_proxy => true;
set no_default_pages => true;
our $VERSION = '0.1';
my $vtapi = VT::API->new(key => '1c55d0f05c41f83e9897c5964324b9a8d191b7fc35bd30c0f4d26ecbaf329700');
my $apikey = 'g97nb8n832x7b6ne9897c5964324b9a8d191b7fc35bd30c0f4d26ecbaf329700';

# Subs ###############################################################################
sub login_page_handler {
    template 'login';
}

sub permission_denied_page_handler {
    template 'denied';
}

# Hooks ###############################################################################
hook 'database_connection_lost' => sub {
    print "Starting up\n";
};

# Get #################################################################################
get '/' => sub {
    template 'index' => { 'title' => 'RTB Online Arena' };
};

get '/api/results' => sub {
    my $sth = database->prepare(
        'SELECT * FROM results',
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

get '/api/nextmatch' => sub {
    my $sth = database->prepare(
        'SELECT * FROM bots where active = 1 order by rand() limit 2',
    );
    $sth->execute();
    my $bots = $sth->fetchall_arrayref({});

print Dumper($bots);
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

get '/rules' => sub {
    template 'rules';
};

get '/stream' => sub {
    template 'stream';
};

get '/results' => sub {
    my $sth = database->prepare(
        'SELECT * FROM results',
    );
    $sth->execute();
    my $results = $sth->fetchall_arrayref({});

    template 'results' => { results => $results}
};

get '/ranking' => sub {
    my $sth = database->prepare(
        'SELECT * FROM bots where active = 1',
    );
    $sth->execute();
    my $bots = $sth->fetchall_arrayref({});

    template 'ranking' => { bots => $bots}
};

get '/maps' => sub {
    template 'maps';
};

get '/maps/randorena' => sub {
    template 'maps_randorena';
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


      template 'profile' => { bots => $bots}
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

post '/api/results' => sub {
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
        #return send_file($botfile, system_path => 1);
    } else {
        return "nope";
    }
};

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
        my $sql3 = 'update bots set last_upload_date = ? , filesize = ? , md5hash = ? where author_id = ? and name = ?';
        my $sth3 = database->prepare($sql3) or die database->errstr;
        my $now = strftime "%Y-%m-%d %H:%M:%S", localtime;
        $sth3->execute($now, $filesize, $filehash, $author_id[0], $botname) or die $sth3->errstr;
    # Its new
    } else {
        my $sql3 = 'insert into bots (author_id, author_name, name, filename, filesize, md5hash) values (?, ?, ?, ?, ?, ?)';
        my $sth3 = database->prepare($sql3) or die database->errstr;
        $sth3->execute($author_id[0], $user->{username}, $botname, $filename, $filesize, $filehash) or die $sth3->errstr;
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
