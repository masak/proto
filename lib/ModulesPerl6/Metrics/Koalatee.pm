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
            calc => sub { $_[0] eq 'failing' ? 0 : 1 },
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
