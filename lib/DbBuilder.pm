package DbBuilder;

use strictures 2;

use Data::GUID;
use File::Path             qw/make_path  remove_tree/;
use Mojo::URL;
use Mojo::UserAgent;
use Mojo::Util             qw/slurp  trim/;
use Types::Common::Numeric qw/PositiveNum/;
use Types::Standard        qw/InstanceOf  Str  Bool  Maybe/;

use DbBuilder::Log;
use DbBuilder::Dist;
use ModulesPerl6::Model::BuildStats;
use ModulesPerl6::Model::Dists;

use Moo;
use namespace::clean;
use experimental 'postderef';

has _app => (
    init_arg => 'app',
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has _db_file => (
    init_arg => 'db_file',
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has _limit => (
    init_arg => 'limit',
    is  => 'ro',
    isa => Maybe[ PositiveNum ],
);

has _logos_dir => (
    init_arg => 'logos_dir',
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has _restart_app => (
    init_arg => 'restart_app',
    is  => 'ro',
    isa => Maybe[ Bool ],
);

has _meta_list => (
    init_arg => 'meta_list',
    is       => 'ro',
    isa      => Str | InstanceOf[qw/Mojo::URL  URI/],
    required => 1,
);

has _model_build_stats => (
    is      => 'lazy',
    default => sub {
        ModulesPerl6::Model::BuildStats->new( db_file => shift->_db_file );
    },
);

has _model_dists => (
    is      => 'lazy',
    default => sub {
        ModulesPerl6::Model::Dists->new( db_file => shift->_db_file );
    },
);

#########################

sub run {
    my $self = shift;

    my $build_id = Data::GUID->new->as_base64;
    log info => "Starting build $build_id";

    $self->_deploy_db;
    make_path $self->_logos_dir => { mode => 0755 };

    my @metas = $self->_metas;
    for ( 0 .. $#metas ) {
        print "---\n";
        log info => 'Processing dist ' . ($_+1) . ' of ' . @metas;
        $self->_model_dists->add(
            DbBuilder::Dist->new(
                meta_url          => $metas[$_],
                build_id          => $build_id,
                logos_dir         => $self->_logos_dir,
                dist_db           => $self->_model_dists,
            )->info
        );
    }

    $self->_save_build_stats;

    if ( $self->_restart_app ) {
        log info => 'Restarting app ' . $self->_app;
        system $^O eq 'MSWin32'
            ? ( $self->_app => 'daemon'    ) # hypnotoad not supported on Win32
            : ( hypnotoad   => $self->_app );
    }

    log info => "Finished build $build_id\n\n\n";

    $self;
}

#########################

sub _deploy_db {
    my $self = shift;

    my $db = $self->_db_file;
    log info => "Using database file $db";
    return $self if -e $db;

    log info => "Database file not found... deploying new database";
    $self->_model_dists      ->deploy;
    $self->_model_build_stats->deploy;

    $self;
}

sub _metas {
    my $self = shift;
    my $meta_list = $self->_meta_list;

    log info => "Loading META.list from $meta_list";
    my $url = Mojo::URL->new( $meta_list );
    my $raw_data;
    if ( $url->scheme and $url->scheme =~ /(ht|f)tps?/i ) {
        log info => '... a URL detected; trying to fetch';
        my $tx = Mojo::UserAgent->new( max_redirects => 10 )->get( $url );

        if ( $tx->success ) { $raw_data = $tx->res->body }
        else {
            my $err = $tx->error;
            log fatal => "$err->{code} response: $err->{message}"
                if $err->{code};
            log fatal => "Connection error: $err->{message}";
        }
    }
    elsif ( -r $meta_list ) {
        log info => '... a file detected; trying to read';
        $raw_data = slurp $meta_list;
    }
    else {
        log fatal => 'Could not figure out how to load META.list. It does '
            . 'not seem to be a URL, but is not a [readable] file either';
    }

    my @metas = grep /\S/, map trim($_), split /\n/, $raw_data;
    log info => 'Found ' . @metas . ' dists';

    return @metas;
}

sub _save_build_stats {
    my $self = shift;

    $self->_model_build_stats->update(
        last_updated => time(),
        dists_num    => scalar( $self->_model_dists->find->@* ),
    );
}

1;

__END__
