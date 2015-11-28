package ModulesPerl6::DbBuilder::Dist;

use ModulesPerl6::DbBuilder::Log;
use Mew;
use Module::Pluggable search_path => ['ModulesPerl6::DbBuilder::Dist::Source'],
                      sub_name    => '_sources',
                      require     => 1;
use Module::Pluggable search_path
                        => ['ModulesPerl6::DbBuilder::Dist::PostProcessor'],
                      sub_name    => '_postprocessors',
                      require     => 1;

has [qw/_build_id  _logos_dir  _meta_url/] => Str;
has _dist_db => InstanceOf['ModulesPerl6::Model::Dists'];

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

    $dist->{build_id} = $self->_build_id;

    return $dist;
}

sub _load_from_source {
    my $self = shift;

    my $url = $self->_meta_url;
    for my $candidate ( $self->_sources ) {
        next unless $url =~ $candidate->re;
        log info => "Using $candidate to load $url";
        my $dist_source = $candidate->new(
            meta_url  => $url,
            logos_dir => $self->_logos_dir,
            dist_db   => $self->_dist_db,
        )
        my $dist = $dist_source->load
            return $self->_salvage_build( $dist_source );

        $dist->{build_id} = $self->_build_id;

        for my $postprocessor ( $self->_postprocessors ) {
            $postprocessor->new(
                meta_url => $url,
                dist     => $dist,
            )->process;
        }

        delete $dist->{_builder};
        return $dist;
    }
    log error => "Could not find a source module that could handle dist URL "
        . "[$url]\nHere are all the source modules currently available:\n"
        . join "\n", map "$_ looks for " . $_->re, $self->_sources;

    return;
}

sub _salvage_build {
    my ( $self, $dist_source ) = @_;

    my $dist = $dist_source->_dist;
    $self->_dist_db->salvage_build( $dist->{url}, $self->_build_id )
        if ref $dist and length $dist->{url};

    return;
}

1;