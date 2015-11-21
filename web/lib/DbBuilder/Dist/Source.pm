package DbBuilder::Dist::Source;

use strictures 2;

use JSON::Meth qw/$json/;
use Mojo::UserAgent;
use Try::Tiny;
use Types::Standard qw/Str/;

use DbBuilder::Log;

use Moo;
use namespace::clean;

has _logos_dir => (
    init_arg => 'logos_dir',
    is       => 'ro',
    isa      => Str,
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

    return $json;
}

sub load { ... }
sub re   { ... }

1;