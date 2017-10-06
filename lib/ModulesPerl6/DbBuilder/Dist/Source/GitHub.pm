package ModulesPerl6::DbBuilder::Dist::Source::GitHub;

use base 'ModulesPerl6::DbBuilder::Dist::Source';

use Carp       qw/croak/;
use Mojo::File qw/path/;
use Mojo::Util qw/decode/;
use Pithub;
use LWP::UserAgent;
use Time::Moment;

use ModulesPerl6::DbBuilder::Log;
use Mew;
use experimental 'postderef';

has _pithub => InstanceOf['Pithub'], (
    is => 'lazy',
    default => sub {
        my $self = shift;
        my ( $user, $repo ) = $self->_meta_url =~ $self->re;
        $self->_dist->{_builder}->@{qw/repo_user  repo/} = ( $user, $repo );
        return Pithub->new(
            user  => $user,
            repo  => $repo,
            token => $self->_token,
            ua    => LWP::UserAgent->new(
                agent   => 'Perl 6 Ecosystem Builder',
                timeout => 20,
            ),
        );
    },
);

has _token => Str, (
    is => 'lazy',
    default => sub {
        my $file = $ENV{MODULES_PERL6_GITHUB_TOKEN_FILE} // 'github-token';
        -r $file or log fatal => "GitHub token file [$file] is missing "
                            . 'or has no read permissions';
        return decode 'utf8', path($file)->slurp;
    },
);

sub re {
    qr{
        ^   https?:// \Qraw.githubusercontent.com\E
            /([^/]+)    # User
            /([^/]+)    # Repo
            /[^/]+      # Branch
            /[^/]+      # Meta file
        $
    }ix
}

sub load {
    my $self = shift;

    log info => 'Fetching distro info and commits';
    my $dist           = $self->_dist or return;
    my $repo           = $self->_repo($self->_pithub->repos->get) or return;
    my $commit_request = $self->_pithub->repos->commits->list;
    my $commits        = $self->_repo($commit_request) or return;

    for ($commit_request->response) {
        my $remaining = $_->header('X-RateLimit-Remaining');
        my $refresh   = $_->header('X-RateLimit-Reset') - time;
        log info => "Rate limiter info: $remaining requests remaining "
            . "(reset in $refresh seconds)";
    }

    %$dist      = (
        %$dist,
        dist_source => 'github',
        url         => $repo->{html_url},
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
    return $dist
        if $dist->{date_updated} eq $date_updated and not $ENV{FULL_REBUILD};

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

    $dist->{_builder}{files} = [
        map +{ url => $_->{url}, name => $_->{path} },
            grep $_->{type} eq 'blob', @$tree
    ];

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

__END__

=encoding utf8

=for stopwords md dist dists

=head1 NAME

ModulesPerl6::DbBuilder::Dist::Source::GitHub - GitHub distribution source

=head1 SYNOPSIS

    if ( $url =~ ModulesPerl6::DbBuilder::Dist::Source::GitHub::re ) {
        my $dist = $source->new(
            meta_url  => $url,
            logos_dir => catdir(qw/public  content-pics  dist-logos/),
            dist_db   => ModulesPerl6::Model::Dists->new,
        )->load or return;
    }

=head1 DESCRIPTION

This Dist Source handles repositories hosted on L<GitHub|http://github.com>.
The URLs matcher expects the META link to point to a raw file, e.g.
L<https://raw.githubusercontent.com/zoffixznet/perl6-modules.perl6.org-test1/master/META.info>

=head1 USED POSTPROCESSORS

This module requests
L<Travis postprocessor|ModulesPerl6::DbBuilder::Dist::PostProcessor::TravisCI>
to be run.

=head1 DOCUMENTATION

See documentation for L<ModulesPerl6::DbBuilder::Dist::Source> for details.

=head1 CONTACT INFORMATION

Original version of this module was written by Zoffix Znet
(L<https://github.com/zoffixznet/>, C<Zoffix> on irc.freenode.net).

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
