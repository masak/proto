package ModulesPerl6::DbBuilder::Dist::PostProcessor;

use ModulesPerl6::DbBuilder::Log;
use Mew;

has _dist     => Maybe[Ref['HASH'] | InstanceOf['JSON::Meth']];
has _meta_url => Str;

sub process { ... }

1;

__END__

=encoding utf8

=for stopwords md dist dists

=head1 NAME

ModulesPerl6::DbBuilder::Dist::PostProcessor - base class for distribution build postprocessors

=head1 SYNOPSIS

    use base 'ModulesPerl6::DbBuilder::Dist::PostProcessor';

    sub process {
        my $self = shift;
        my $dist = $self->_dist or return;
        my $meta = $self->_meta_url;
        ...
        do stuff
    }

=head1 DESCRIPTION

A I<Dist PostProcessor> is a thing that does more things when all the
information about a distribution has been collected by one of the
L<dist sources|ModulesPerl6::DbBuilder::Dist::Source>. L<Determining Travis
build status|ModulesPerl6::DbBuilder::Dist::PostProcessor::TravisCI> is one
example of what a I<Dist PostProcessor> can be doing.

This class is a base class for all I<Dist PostProcessors> that defines
common interface.

=head1 CONSTRUCTOR ARGUMENTS

    My::Awesome::PostProcessor->new(
        meta_url => $url_to_dist_META_file,
        dist     => $dist_info_hashref,
    )->process;

Several arguments will be provided by the main build script to the subclassed
PostProcessor. These are:

=head2 C<metal_url>

See L</_meta_url> private attribute.

=head2 C<dist>

See L</_dist> private attribute.

=head1 PROVIDED PUBLIC METHODS

=head2 C<process>

    sub process { ... }

    # Subclass:
    sub process {
        my $self = shift;
        my $dist = $self->_dist or return;
        my $meta = $self->_meta_url;
        ...
        do stuff
    }

This method is a stub and must be overriden by subclasses. No arguments
are passed and no return value is collected. You can obtain the hashref
containing distribution's information via L<_dist private_method/_dist>
and you can alter dist's info it by modifying that hashref directly.

It is recommended to make decisions on whether your PostProcessor should run
based on a specific key present in the L<_builder
store key|ModulesPerl6::DbBuilder::Dist::Source/_builder>.

=head1 PRIVATE ATTRIBUTES

B<Note:> these attributes are private to your subclass. Do not rely on them
from the ouside of it.

=head2 C<_dist>

    $self->_dist->{name} = 'My::Awesome::Dist';

Returns a hashref containing information about a distribution.
See L<_dist method in Dist Source
baseclass|ModulesPerl6::DbBuilder::Dist::Source/_dist> for details on what
the C<_dist> hashref looks like, keeping in mind a PostProcessor will be
seeing that hashref filled with values by the Dist Source.

=head3 C<_meta_url>

    my ( $user, $repo ) = $self->_meta_url =~ $self->re;

Returns the URL for dist's
L<META file|http://design.perl6.org/S22.html#META6.json>.

=head1 CONTACT INFORMATION

Original version of this module was written by Zoffix Znet
(L<https://github.com/zoffixznet/>, C<Zoffix> on irc.freenode.net).

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.

