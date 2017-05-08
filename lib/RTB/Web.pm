package RTB::Web;
use Dancer2;
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::Database;
use Dancer2::Plugin::Passphrase;
use Dancer2::Template::TemplateToolkit;
use Dancer2::Session::Cookie;

# Defines #############################################################################
set behind_proxy => true;
set no_default_pages => true;
our $VERSION = '0.1';
our @filetypes = ("application/octet-stream","","","");

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

get '/admin' => require_role admin => sub {
    template 'admin';
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
    my $data = request->upload('file');
    my $path;
 
    my $dir = path(config->{appdir}, 'botuploads');
    mkdir $dir if not -e $dir;

    my $filetype = $data->type;
    my $filesize = $data->size;
    my $maxfilesize = 500000;

    if ($filesize > $maxfilesize) {
        return "Upload failed! - $filetype - $filesize - exceeds 500kb";
    }

    my %allowed = map { $_ => 1 } @filetypes;
    if(exists($allowed{$filetype})) { } else {
        return "Upload failed! - $filetype - $filesize - $filetype is not allowed";
    }

    my $uploadname = $data->{filename};
    my $extension;
    if ($uploadname =~ /.+\.(.+)/) {
        $extension = $1;
    }

    if ($extension) {
        $path = path($dir, "$user->{username}.$extension");
    } else {
        $path = path($dir, "$user->{username}");
    }
    $data->copy_to($path);
    return "Upload success! - $filetype - $filesize";
};

post '/login' => sub {
    my ($success, $realm) = authenticate_user(
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
