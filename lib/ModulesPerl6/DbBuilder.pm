package ModulesPerl6::DbBuilder;

use Data::GUID;
use File::Glob            qw/bsd_glob/;
use File::Path            qw/make_path  remove_tree/;
use File::Spec::Functions qw/catfile/;
use Mojo::URL;
use Mojo::UserAgent;
use Mojo::Util            qw/slurp  trim/;
use Try::Tiny;

use ModulesPerl6::DbBuilder::Log;
use ModulesPerl6::DbBuilder::Dist;
use ModulesPerl6::Model::BuildStats;
use ModulesPerl6::Model::Dists;
use Mew;
use experimental 'postderef';

has [qw/_app  _db_file  _logos_dir/] => Str;
has -_interval    => PositiveOrZeroNum;
has -_limit       => Maybe[ PositiveNum ];
has -_restart_app => Maybe[ Bool ];
has _meta_list    => Str;
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
    $ENV{FULL_REBUILD}
        and log info => "Full rebuild requested. Caches should be invalid";

    $self->_deploy_db;

    log info => "Will be saving images to " . $self->_logos_dir;
    make_path $self->_logos_dir => { mode => 0755 };

    my @metas = $self->_metas;
    for my $idx ( 0 .. $#metas ) {
        try {
            warn "---\n";
            log info => 'Processing dist ' . ($idx+1) . ' of ' . @metas;
            my $dist = ModulesPerl6::DbBuilder::Dist->new(
                meta_url  => $metas[$idx],
                build_id  => $build_id,
                logos_dir => $self->_logos_dir,
                dist_db   => $self->_model_dists,
            )->info or die "Failed to build dist\n";
            $self->_model_dists->add( $dist );

            # This interval, when defaulted to at least 5, prevents us from
            # going over GitHub's rate-limit of 5,000 requests per hour.
            # This should likely be moved/adjusted when we have more Dist
            # Sources or if we starting making more/fewer API requests per dist
            sleep $self->_interval // 0;
        }
        catch {
            log error=> "Received fatal error while building $metas[$idx]: $_";
            $self->_model_dists->salvage_build( $metas[$idx], $build_id );
        };
    }

    warn "---\n---\n";
    log info => 'Finished building all dists. Performing cleanup.';

    $self->_remove_old_dists( $build_id )
        ->_remove_old_logotypes->_save_build_stats;

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

sub _remove_old_logotypes {
    my $self = shift;

    # TODO: we can probably move this code into the ::Dists model so we don't
    # have to pull all the dists in DB into a giant list of hashrefs
    my $dir = $self->_logos_dir;
    my %logos = map +( $_ => 1 ),
        grep -e, map catfile($dir, 's-' . $_->{name} =~ s/\W/_/gr . '.png'),
            $self->_model_dists->find->each;

    for ( grep ! $logos{$_}, bsd_glob catfile $dir, '*' ) {
        log info => "Removing logotype file without a dist in db: $_";
        unlink;
    }

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
