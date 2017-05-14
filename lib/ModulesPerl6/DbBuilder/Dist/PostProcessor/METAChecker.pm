package ModulesPerl6::DbBuilder::Dist::PostProcessor::METAChecker;

use strictures 2;
use base 'ModulesPerl6::DbBuilder::Dist::PostProcessor';

use Mojo::UserAgent;
use ModulesPerl6::DbBuilder::Log;
use experimental 'postderef';

sub problem {
    my ($problem, $severity) = @_;
    { problem => $problem, severity => $severity }
}

sub process {
    my $self = shift;
    my $dist = $self->_dist;

    my $repo_url = 'https://github.com/'
        . join '/', grep length, @{ $dist->{_builder} }{qw/repo_user  repo/};

    my @problems;
    unless ($dist->{_builder}{has_manifest}) {
        push @problems, problem("dist has no MANIFEST file", 3);
    }

    if ($dist->{_builder}{no_author_set}) {
        push @problems, problem("dist has no author(s) specified", 3);
    }

    if ($dist->{_builder}{has_no_readme}) {
        push @problems, problem("dist has no readme", 1);
    }

    if ($dist->{_builder}{mentions_old_tools}) {
        push @problems, problem("dist mentions discouraged tools (panda, ufo etc.) in the readme", 2);
    }

    length $dist->{ $_ } or push @problems, problem("required `$_` field is missing", 5)
        for qw/perl  name  version  description  provides/;

    push @problems, problem("dist does not have any tags", 1)
        unless @{ $dist->{tags} };

    push @problems, problem("dist does not have a version set", 5)
        unless ($dist->{version} and $dist->{version} ne '*');

    $dist->{problems} = \@problems;

    if ( $repo_url eq $dist->{url} ) {
        log info => "dist source URL is same as META repo URL ($repo_url)";
        return;
    }

    my $code = Mojo::UserAgent->new( max_redirects => 5 )
        ->get( $dist->{url} )->res->code;

    log +( $code == 200 ? 'info' : 'error' ),
        "HTTP $code when accessing dist source URL ($dist->{url})";

    return 1;
}

1;

__END__

=encoding utf8

=for stopwords md dist dists

=head1 NAME

ModulesPerl6::DbBuilder::Dist::PostProcessor::METAChecker - postprocessor that checks META6.json info is correct

=head1 CONTACT INFORMATION

Original version of this module was written by Zoffix Znet
(L<https://github.com/zoffixznet/>, C<Zoffix> on irc.freenode.net).

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
