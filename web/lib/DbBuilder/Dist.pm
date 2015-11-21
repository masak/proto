package DbBuilder::Dist;

use strictures 2;
use Types::Standard qw/Ref  Maybe  Str/;
use DbBuilder::Log;
use Moo;
use namespace::clean;
use Module::Pluggable search_path => ['DbBuilder::Dist::Source'],
                      sub_name    => '_sources',
                      require     => 1;

has _build_id => (
    init_arg => 'build_id',
    is       => 'ro',
    isa      => Str,
    required => 1,
);

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

#########################

sub info {
    my $self = shift;
    my $info = $self->_load_info
        or return;

    return $info;
}

#########################

sub _load_info {
    my $self = shift;

    my $dist = $self->_load_from_source
        or return;

    $dist->{build_id}      = $self->_build_id;
    $dist->{travis_status} = 'unknown';

    return $dist;
}

sub _load_from_source {
    my $self = shift;

    my $url = $self->_meta_url;
    for my $source ( $self->_sources ) {
        next unless $url =~ $source->re;
        log info => "Using $source to load $url";
        return $source->new(
            meta_url  => $url,
            logos_dir => $self->_logos_dir
        )->load;
    }
    log error => "Could not find a source module that could handle dist URL "
        . "[$url]\nHere are all the source modules currently available:\n"
        . join "\n", map "$_ looks for " . $_->re, $self->_sources;

    return;
}

1;