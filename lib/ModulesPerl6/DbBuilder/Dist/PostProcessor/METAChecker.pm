package ModulesPerl6::DbBuilder::Dist::PostProcessor::METAChecker;

use strictures 2;
use base 'ModulesPerl6::DbBuilder::Dist::PostProcessor';

use Mojo::UserAgent;
use ModulesPerl6::DbBuilder::Log;
use experimental 'postderef';

sub process {
    my $self = shift;
    my $dist = $self->_dist;
    return unless $dist->{_builder}{is_fresh};

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
