package ModulesPerl6::Model::SiteTips;

use strictures 2;
use Carp                     qw/croak/;
use File::Spec::Functions    qw/catfile/;
use FindBin; FindBin->again;
use Mojo::Util               qw/trim/;

use Moo;
use namespace::clean;

has _tips => (
    is      => 'lazy',
    default => sub { shift->_load_tip_file },
);

has _tip_file => (
    is       => 'lazy',
    init_arg => 'tip_file',
    default  =>  sub {
        $ENV{MODULESPERL6_TIP_FILE}
            // catfile $FindBin::Bin, qw/.. site-tips.txt/;
    },
);

sub _load_tip_file {
    my $self = shift;
    my $file = $self->_tip_file;

    open my $fh, '<', $file
        or croak "Could not open site tips file [$file] for reading: $!";

    my @tips;
    while ( <$fh> ) {
        $_ = trim $_;
        next unless /\S/ and not /^#/;
        push @tips, $_;
    }

    return \@tips;
}

sub tip {
    my $self = shift;
    my $tips = $self->_tips;
    return $tips->[ rand @$tips ];
}

1;

__END__

=encoding utf8

=head1 NAME

ModulesPerl6::Model::SiteTips - model representing site usage tips for users

=head1 SYNOPSIS

    my $m = ModulesPerl6::Model::SiteTips->new( tip_file => 'tips.txt' );

    say $m->tip;

=head1 DESCRIPTION

This module is used to access site usage tips that are shown to users.

=head1 TIP FILE FORMAT

    # This is a comment and will be ignored, as are blank lines

    Tip 1
    Tip 2

The tip file is just a regular text file where each tip occupies a single
line. Blank lines are ignored as are lines that start with C<#>. HTML code
is allowed and will B<NOT> be escaped.

See L</tip_file> for info on where the module will look for the tip file.

=head1 METHODS

=head2 C<new>

    my $m = ModulesPerl6::Model::SiteTips->new;

    my $m = ModulesPerl6::Model::SiteTips->new( tip_file => 'tips.txt' );

Creates and returns a new C<ModulesPerl6::Model::SiteTips> object. Takes
these arguments:

=head3 C<tip_file>

    my $m = ModulesPerl6::Model::SiteTips->new( tip_file => 'tips.txt' );

Specifies the file to use to read tips from. B<Defaults to:>
C<MODULESPERL6_TIP_FILE> environmental variable, if set, or
C<../site-tips.txt> relative to the location of the script.

=head3 C<tip>

    my $tip = $m->tip;

Returns a randomly-chosen tip. B<NOTE:> this method does B<NOT> escape HTML
and HTML code I<is> allowed in the tips.

=head1 CONTACT INFORMATION

Original version of this module was written by Zoffix Znet
(L<https://github.com/zoffixznet/>, C<Zoffix> on irc.freenode.net).

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
