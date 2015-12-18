package ModulesPerl6::DbBuilder::Dist::PostProcessor::TravisCI;

use strictures 2;
use base 'ModulesPerl6::DbBuilder::Dist::PostProcessor';

use Mojo::UserAgent;
use ModulesPerl6::DbBuilder::Log;
use experimental 'postderef';

sub process {
    my $self = shift;
    my $dist = $self->_dist;

    # Fetch travis status only for dists that had new commits in the past 24hr
    return if ($dist->{date_updated}//0) < (time - 60*60*24)
        and not $dist->{_builder}{is_fresh} and not $ENV{FULL_REBUILD};
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

__END__

=encoding utf8

=for stopwords md dist dists

=head1 NAME

ModulesPerl6::DbBuilder::Dist::PostProcessor::TravisCI - postprocessor that determines Travis build status

=head1 SYNOPSIS

    # In your Dist Source:
    $dist->{_builder}{is_fresh}   = 1; # Has new commits
    $dist->{_builder}{has_travis} = 1; # Dist has .travis.yml file

    # After preprocessor is run:
    say $dist->{travis_status}; # says 'passing' for passing Travis builds

=head1 DESCRIPTION

This is a subclass of L<ModulesPerl6::DbBuilder::Dist::PostProcessor> that
implements fetching Travis build information.

=head1 EXPECTED DIST KEYS

=head2 C<{date_updated}>

    $dist->{date_updated} = time;

This boolean key indicates when the dist's last commit was done. The
postprocessor won't attempt to fetch new Travis info for commits older than
24 hours.

=head2 C<{_builder}{is_fresh}>

    $dist->{_builder}{is_fresh} = 1;

This boolean key indicates a dist has fresh commits (based on the current
data in the database). The presence of this key will trigger Travis info
fetch regardless of the value of C<{date_updated}> key.

=head2 C<{_builder}{has_travis}>

    $dist->{_builder}{has_travis} = 1;

This boolean key indicates the dist has a C<.travis.yml> file. If this is not
set, the postprocessor won't run.

=head1 SET DIST KEYS

=head2 C<{travis_status}>

    say $dist->{travis_status};

After the postprocessor finishes it will set the C<travis_status> dist key
to the string indicating the Travis build status (e.g. C<failing>,
C<passing>, C<error>, etc.)

=head1 CONTACT INFORMATION

Original version of this module was written by Zoffix Znet
(L<https://github.com/zoffixznet/>, C<Zoffix> on irc.freenode.net).

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
