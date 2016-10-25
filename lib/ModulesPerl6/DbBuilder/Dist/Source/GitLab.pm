package ModulesPerl6::DbBuilder::Dist::Source::GitLab;

use base 'ModulesPerl6::DbBuilder::Dist::Source';

use Carp       qw/croak/;
use Mojo::Util qw/slurp  decode/;

use ModulesPerl6::DbBuilder::Log;
use Mew;
use experimental 'postderef';

sub re {
    qr{
        ^   https?:// \Qgitlab.com\E
            /([^/]+)    # User
            /([^/]+)    # Repo
            /[^/]+      # raw
            /[^/]+      # Branch
            /[^/]+      # Meta file
        $
    }ix;
}

sub load {
    my $self = shift;

    log info => 'Fetching distro info and commits';
    my $dist    = $self->_dist or return;

    $dist->{author_id} = $dist->{_builder}{repo_user}
        if $dist->{author_id} eq 'N/A';

    $dist->{date_updated}=undef; # XXX displays as Epoch start in UI

    return if $dist->{name} eq 'N/A';

    # TODO: Add proper check for whether we got new commits
    $dist->{_builder}{is_fresh} = 1;
    return $dist;
}

1;

__END__

=encoding utf8

=for stopwords md dist dists

=head1 NAME

ModulesPerl6::DbBuilder::Dist::Source::GitLab - GitLab distribution source

=head1 DOCUMENTATION

See documentation for L<ModulesPerl6::DbBuilder::Dist::Source> for details.

=head1 CONTACT INFORMATION

Original version of this module was written by Zoffix Znet
(L<https://github.com/zoffixznet/>, C<Zoffix> on irc.freenode.net).

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
