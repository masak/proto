package ModulesPerl6::Metrics::Koalatee;

use Mew;

sub total {
    my ( $self, $dist ) = @_;

    my $details = $self->details( $dist );
    my ( $max, $koality );
    for ( @$details ) {
        $max     += $_->{max};
        $koality += $_->{val};
    }

    return sprintf '%.f', 100 * $koality / $max;
}

sub details {
    my ( $self, $dist ) = @_;

    my @details = (
        {
            name => 'has_readme',
            desc => 'Does a distribution have a README file?',
            max  => 1,
        },
        {
            name => 'has_tests',
            desc => 'Does a distribution have tests?',
            max  => 1,
        },
        {
            name => 'panda',
            desc => 'META file conformance level to spec',
            max  => 2,
        },
        {
            name => 'travis_status',
            desc => 'This metric does not pass for distributions '
                        . 'with failing Travis-CI builds',
            max  => 1,
            calc => sub { ($_[0]//'') eq 'failing' ? 0 : 1 },
        }
    );

    for ( @details ) {
        $_->{val} = $_->{calc} ? $_->{calc}->( $dist->{ $_->{name} } )
                               : $dist->{ $_->{name} };
        $_->{val} //= 0;
    }

    delete $_->{calc} for @details;
    return \@details;
}

1;

__END__

=encoding utf8

=head1 NAME

ModulesPerl6::Metrics::Koalatee - Koalatee metric

=head1 SYNOPSIS

    my $m = ModulesPerl6::Metrics::Koalatee->new;

    say $m->total( $dist );

=head1 DESCRIPTION

This module is used to calculate the Koalitee of the dist. Koalitee is a
bastardization of "Quality" with fuzzy bears in mind. In some respects, this
metric represents the quality of a distribution.

=head1 METHODS

=head2 C<new>

    my $m = ModulesPerl6::Metrics::Koalatee->new;

Creates and returns a new C<ModulesPerl6::Metrics::Koalatee> object. Takes
no arguments.

=head2 C<total>

    say $m->total( $dist );

Calculates the total pecent of Koalatee of a dist
(C<100%> is returned as C<100>). Takes a hashref of a dist with metrics to
measure. See L</details> for what keys are available and what they mean.

=head2 C<details>

    use Data::Dumper;
    say Dumper $m->total( $dist );

    # Dump:
    #    [
    #        {
    #            name => 'has_readme',
    #            desc => 'Does a distribution have a README file?',
    #            max  => 1,
    #            val  => 0,
    #        },
    #        {
    #            name => 'has_tests',
    #            desc => 'Does a distribution have tests?',
    #            max  => 1,
    #            val  => 0,
    #        },
    #        {
    #            name => 'panda',
    #            desc => 'META file conformance level to spec',
    #            max  => 2,
    #            val  => 2,
    #        },
    #        {
    #            name => 'travis_status',
    #            desc => 'This metric does not pass for distributions '
    #                        . 'with failing Travis-CI builds',
    #            max  => 1,
    #            val  => 1,
    #        }
    #    ];

Takes a dist hashref with metric measures and returns an arrayref of hashrefs,
where each hashref is a Koalitee metric, which has these keys:

=head3 C<name>

The name of a metric. This is the key that will be looked up in the
dist hashref, which, if missing, will be assumed to have value of zero.

=head3 C<desc>

Human-readable description of the metric.

=head3 C<max>

The maximum possible value for the metric, with the lower end being C<0>.

=head3 C<val>

The calculated value of the metric.

=head3 C<calc>

    calc => sub { ($_[0]//'') eq 'failing' ? 0 : 1 },

B<PRIVATE!!!> This is a private key that will never be returned by the method.
It's documented for future developers of this module who can edit the source.
The key takes a subref whose C<@_> will contain the value of the metric
measure. The return value will be assigned to L</val> key.

=head1 CONTACT INFORMATION

Original version of this module was written by Zoffix Znet
(L<https://github.com/zoffixznet/>, C<Zoffix> on irc.freenode.net).

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
