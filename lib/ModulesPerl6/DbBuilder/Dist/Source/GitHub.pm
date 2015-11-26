package ModulesPerl6::DbBuilder::Dist::Source::GitHub;

use strictures 2;
use base 'ModulesPerl6::DbBuilder::Dist::Source';

use Carp       qw/croak/;
use Mojo::Util qw/slurp  decode/;
use Pithub;
use Time::Moment;

use ModulesPerl6::DbBuilder::Log;

use Moo;
use namespace::clean;
use experimental 'postderef';

has _pithub => (
    is => 'lazy',
    default => sub {
        my $self = shift;
        my ( $user, $repo ) = $self->_meta_url =~ $self->re;
        $self->_dist->{_builder}->@{qw/repo_user  repo/} = ( $user, $repo );
        return Pithub->new(
            user  => $user,
            repo  => $repo,
            token => $self->_token,
        );
    },
);

has _token => (
    is => 'lazy',
    default => sub {
        my $file = $ENV{MODULES_PERL6_GITHUB_TOKEN_FILE} // 'github-token';
        -r $file or log fatal => "GitHub token file [$file] is missing "
                            . 'or has no read permissions';
        return decode 'utf8', slurp $file;
    },
);

sub re { qr{^https?://\Qraw.githubusercontent.com\E/([^/]+)/([^/]+)}i }

sub load {
    my $self = shift;
# use Acme::Dump::And::Dumper;
# die DnD [ 42 ];
    log info => 'Fetching distro info and commits';
    my $dist    = $self->_dist or return;
    my $repo    = $self->_repo($self->_pithub->repos->get)           or return;
    my $commits = $self->_repo($self->_pithub->repos->commits->list) or return;

    %$dist      = (
        %$dist,
        url         => $repo->{url},
        issues      => $repo->{open_issues_count} // 0,
        stars       => $repo->{stargazers_count}  // 0,
    );

    $dist->{author_id} = $dist->{_builder}{repo_user}
        if $dist->{author_id} eq 'N/A';

    return if $dist->{name} eq 'N/A';

    my $date_updated = eval {
        Time::Moment->from_string( $commits->[0]{commit}{committer}{date} )
            ->epoch
    } // 0;

    # no new commits and we have cached results that will do just fine
    return $dist if $dist->{date_updated} eq $date_updated;
    $dist->{date_updated} = $date_updated;

    log info => 'Dist has new commits. Fetching more info.';
    $dist->{_builder}{is_fresh} = 1;

    my $tree = $self->_repo(
        $self->_pithub->git_data->trees
            ->get( sha => $commits->[0]{sha}, recursive => 1 )
    ) or return;
    $tree = $tree->{tree};

    $self->_save_logo(
        map $_->{size}, grep $_->{path} eq 'logotype/logo_32x32.png', @$tree
    );

    # ::Dists model will ignore other metrics if we explicitly tell it the
    # kwalitee of a distro;
    delete $dist->{kwalitee};
    $self->_set_readme( map $_->{path}, grep $_->{type} eq 'blog', @$tree );
    $self->_set_tests(  map $_->{path}, grep $_->{type} eq 'tree', @$tree );

    $dist->{_builder}{has_travis} = grep $_->{path} eq '.travis.yml', @$tree;

    return $dist;
}

sub _repo {
    my ( $self, $res ) = @_;

    unless ( $res->success ) {
        log error => "Error accessing GitHub API. HTTP Code: " . $res->code;
        return
    }

    return $res->content;
}

1;