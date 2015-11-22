package DbBuilder::Dist::Source;

use strictures 2;

use JSON::Meth qw/$json/;
use Mojo::UserAgent;
use Try::Tiny;
use Types::Standard qw/InstanceOf  Str/;

use DbBuilder::Log;

use Moo;
use namespace::clean;

has _logos_dir => (
    init_arg => 'logos_dir',
    is       => 'ro',
    isa      => Str,
    required => 1,
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

sub _download_meta {
    my $self = shift;
    my $url = $self->_meta_url;

    log info => "Downloading META file from $url";
    my $tx = Mojo::UserAgent->new( max_redirects => 10 )->get( $url );

    if ( $tx->success ) { return $tx->res->body }
    else {
        my $err = $tx->error;
        log error => "$err->{code} response: $err->{message}"
            if $err->{code};
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

    return return $self->_fill_missing( $json );
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
        author_id     => 'N/A',
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

sub _is_any_readme {
    my ( $self, @files ) = @_;
    my %readmees = map +( "README$_" => 1 ), '', # just 'README'; no ext.
        qw/.pod  .pod6  .md        .mkdn  .mkd  .markdown  .mkdown  .ron
           .rst  .rest  .asciidoc  .adoc  .asc  .txt/;

    return grep( $readmees{$_}, @files ) ? 1 : 0;
}

sub _is_any_tests {
    my ( $self, @files ) = @_;
    my %tests = map +( $_ => 1 ), qw/t  test  tests/;

    return grep( $tests{$_}, @files ) ? 1 : 0;
}

sub load { ... }
sub re   { ... }

1;