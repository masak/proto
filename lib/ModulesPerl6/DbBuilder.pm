package ModulesPerl6::DbBuilder;

use strictures 2;

use Data::GUID;
use File::Path             qw/make_path  remove_tree/;
use Mojo::URL;
use Mojo::UserAgent;
use Mojo::Util             qw/slurp  trim/;
use Try::Tiny;
use Types::Common::Numeric qw/PositiveNum  PositiveOrZeroNum/;
use Types::Standard        qw/InstanceOf  Str  Bool  Maybe/;

use ModulesPerl6::DbBuilder::Log;
use ModulesPerl6::DbBuilder::Dist;
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

has _interval => (
    init_arg => 'interval',
    is  => 'ro',
    isa => PositiveOrZeroNum,
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
    for my $idx ( 0 .. $#metas ) {
        try {
            print "---\n";
            log info => 'Processing dist ' . ($idx+1) . ' of ' . @metas;
            $self->_model_dists->add(
                ModulesPerl6::DbBuilder::Dist->new(
                    meta_url          => $metas[$idx],
                    build_id          => $build_id,
                    logos_dir         => $self->_logos_dir,
                    dist_db           => $self->_model_dists,
                )->info
            );

            # This interval, when defaulted to at least 5, prevents us from
            # going over GitHub's rate-limit of 5,000 requests per hour.
            # This should likely be moved/adjusted when we have more Dist
            # Sources or if we starting making more/fewer API requests per dist
            sleep $self->_interval;
        }
        catch {
            log error=>  "Received fatal error while building $metas[$idx]: $_";
        };
    }

    $self->_remove_old_dists( $build_id )->_save_build_stats;

    if ( $self->_restart_app ) {
        log info => 'Restarting app ' . $self->_app;
        if ( $^O eq 'MSWin32' ) {
            $SIG{CHLD} = 'IGNORE';
            my $pid = fork;
            $pid == 0 and exec $self->_app => 'daemon';
            not defined $pid and log error => "Failed to fork to exec the app";
        }
        else {
            0 == system hypnotoad => $self->_app
                or log error => "Failed to restart the app: $?";
        }
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

    if ( my $limit = $self->_limit ) {
        @metas = splice @metas, 0, $limit;
        log info => "Limiting build to $limit dists due to explicit request";
    }

    return @metas;
}

sub _remove_old_dists {
    my ( $self, $build_id ) = @_;

    my $delta = $self->_model_dists->remove_old( $build_id );
    log info => "Removed $delta dists that are no longer in the ecosystem"
        if $delta;

    $self;
}

sub _save_build_stats {
    my $self = shift;

    $self->_model_build_stats->update(
        last_updated => time(),
        dists_num    => scalar( $self->_model_dists->find->@* ),
    );

    $self;
}

1;

__END__
