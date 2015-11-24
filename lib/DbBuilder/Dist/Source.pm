package DbBuilder::Dist::Source;

use strictures 2;

use File::Spec::Functions qw/catfile/;
use JSON::Meth qw/$json/;
use Mojo::UserAgent;
use Mojo::Util qw/spurt/;
use Try::Tiny;
use Types::Standard qw/InstanceOf  Maybe  Ref  Str/;

use DbBuilder::Log;

use Moo;
use namespace::clean;

has _logos_dir => (
    init_arg => 'logos_dir',
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has _dist => (
    is => 'lazy',
    isa => Maybe[Ref['HASH'] | InstanceOf['JSON::Meth']],
    default => sub {
        my $self = shift; $self->_parse_meta( $self->_download_meta );
    },
);

has _dist_db => (
    init_arg => 'dist_db',
    is       => 'ro',
    isa      => InstanceOf['ModulesPerl6::Model::Dists'],
    required => 1,
);

has _meta_url => (
    init_arg => 'meta_url',
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has _ua => (
    is      => 'lazy',
    isa     => InstanceOf['Mojo::UserAgent'],
    default => sub { Mojo::UserAgent->new( max_redirects => 10 ) },
);

sub _download_meta {
    my $self = shift;
    my $url = $self->_meta_url;

    log info => "Downloading META file from $url";
    my $tx = $self->_ua->get( $url );

    if ( $tx->success ) { return $tx->res->body }
    else {
        my $err = $tx->error;
        log error => "$err->{code} response: $err->{message}" if $err->{code};
        log error => "Connection error: $err->{message}";
    }

    return;
}

sub _parse_meta {
    my ( $self, $data ) = @_;

    log info => 'Parsing META file';
    eval { $data or die "No data to parse\n"; $data->$json };
    if ( $@ ) { log error => "Failed to parse: JSON error: $@"; return; }

    length $json->{ $_ } or log warn => "Required `$_` field is missing"
        for qw/perl  name  version  description  provides/;

    $json->{normalized_url}
             = $json->{'source-url'}
            // $json->{'repo-url'}
            // $json->{support}{source};

    return $self->_fill_missing( $json );
}

sub _fill_missing {
    my ( $self, $dist ) = @_;

    my $old_dist_data;
    if ( length $dist->{name} ) {
        $old_dist_data
        = $self->_dist_db->find({ name => $dist->{name} })->first;
    }

    %$dist = (
        name          => 'N/A',
        author_id     => $dist->{author}
                            // (@{ $dist->{authors}||[] })[0] // 'N/A',
        url           => 'N/A',
        description   => 'N/A',
        logo          => 'N_A',
        stars         => 0,
        issues        => 0,
        date_updated  => 0,
        date_added    => 0,

        %{ $old_dist_data || {} },

        # Kwalitee metrics
        has_readme    => 0,
        has_tests     => 0,
        panda         => $dist->{'source-url'} && $dist->{provides}
                            ? 2 : $dist->{'source-url'} ? 1 : 0,

        %$dist,
    );

    return $dist;
}

sub _save_logo {
    my ( $self, $size ) = @_;
    my $dist = $self->_dist;
    return unless $size and $dist and $dist->{name} ne 'N/A';
    log info => "Dist has a logotype of size $size bytes.";

    my $logo
    = catfile $self->_logos_dir, 's-' . $dist->{name} =~ s/\W/_/gr . '.png';
    return 1 if -e $logo and -s $logo == $size; # 99% we already got that logo

    log info => 'Did not find cached dist logotype. Downloading.';
    my $repo_root = $self->_meta_url =~ s{[^/]+$}{}r;
    my $tx = $self->_ua->get("$repo_root/logotype/logo_32x32.png");

    unless ( $tx->success ) {
        my $err = $tx->error;
        log error => "$err->{code} response: $err->{message}" if $err->{code};
        log error => "Connection error: $err->{message}";
        return;
    }

    spurt $tx->res->body => $logo;
    return 1;
}

sub _set_readme {
    my ( $self, @files ) = @_;
    my %readmees = map +( "README$_" => 1 ), '', # just 'README'; no ext.
        qw/.pod  .pod6  .md        .mkdn  .mkd  .markdown  .mkdown  .ron
           .rst  .rest  .asciidoc  .adoc  .asc  .txt/;

    my $dist = $self->_dist or return;
    $dist->{has_readme} = grep( $readmees{$_}, @files ) ? 1 : 0;

    $self;
}

sub _set_tests {
    my ( $self, @files ) = @_;
    my %tests = map +( $_ => 1 ), qw/t  test  tests/;

    my $dist = $self->_dist or return;
    $dist->{has_tests} = grep( $tests{$_}, @files ) ? 1 : 0;

    $self;
}

sub load { ... }
sub re   { ... }

1;