package ModulesPerl6::DbBuilder::Dist::PostProcessor::TravisCI;

use strictures 2;
use base 'ModulesPerl6::DbBuilder::Dist::PostProcessor';

use Mojo::UserAgent;
use ModulesPerl6::DbBuilder::Log;

use experimental 'postderef';

sub process {
    my $self = shift;
    my $dist = $self->_dist;

    return unless $dist->{_builder}{is_fresh};
    delete $dist->{travis_status}; # toss cached Travis status
    return unless $dist->{_builder}{has_travis};

    my ( $user, $repo ) = $dist->{_builder}->@{qw/repo_user  repo/};
    return unless length $user and length $repo;

    my @builds = eval {
        Mojo::UserAgent->new( max_redirects => 5 )->get(
            "https://api.travis-ci.org/repos/$user/$repo/builds"
            => { Accept => 'application/vnd.travis-ci.2+json' }
        )->res->json->{builds}->@*;
    }; if ( $@ ) { log error => "Error fetching travis status: $@"; return; }

    $dist->{travis_status} = $self->_get_travis_status( @builds );
    log info => "Determined travis status is $dist->{travis_status}";

    return 1;
}

sub _get_travis_status {
    my ( $self, @builds ) = @_;

    return 'unknown' unless @builds;
    my $state = $builds[0]->{state};

    return $state    if $state =~ /cancel|pend/;
    return 'error'   if $state =~ /error/;
    return 'failing' if $state =~ /fail/;
    return 'passing' if $state =~ /pass/;
    return 'unknown';
}

1;