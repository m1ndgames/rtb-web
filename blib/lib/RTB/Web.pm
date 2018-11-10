package RTB::Web;
use Dancer2;
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::Database;
use Dancer2::Plugin::Passphrase;
use Dancer2::Template::TemplateToolkit;
use Dancer2::Session::Memcached;
use Chess::Elo qw(:all);
use VT::API;
use Data::Dumper;

# Defines #############################################################################
set behind_proxy => true;
set no_default_pages => true;
our $VERSION = '0.1';
my $vtapi = VT::API->new(key => '1c55d0f05c41f83e9897c5964324b9a8d191b7fc35bd30c0f4d26ecbaf329700');

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

get '/video' => sub {
    template 'video';
};

get '/results' => sub {
    template 'results';
};

get '/login' => sub {
    template 'login';
};

get '/profile' => require_login sub {
    template 'profile';
};

# Post ################################################################################
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

    $path = path($dir, "$user->{username}_$botname.$extension");
    $data->copy_to($path);

    # Virus scan
    my $virus_response = $vtapi->scan_file($path);
print Dumper($virus_response);
    # Transfer the bot to game vm


    # Write to db
    my $sth = database->prepare(
        'SELECT id FROM users WHERE username = ?',
    );
    $sth->execute($user->{username});
    my @author_id = $sth->fetchrow_array;

    my $sql2 = 'insert into bots (author_id, name) values (?, ?)';
    my $sth2 = database->prepare($sql2) or die database->errstr;
    $sth2->execute($author_id[0], $botname) or die $sth2->errstr;

    template 'uploadsuccess.tt';
};

post '/login' => sub {
    my ($success,$realm) = authenticate_user(
        params->{username}, params->{password}
    );

    if ($success) {
        session logged_in_user => params->{username};
        session logged_in_user_realm => $realm;
        template 'loggedin.tt';
    } else {
        redirect '/login';
    }
};

# ANY #################################################################################
any '/logout' => sub {
    session->destroy;
};

# EOF #################################################################################
true;
