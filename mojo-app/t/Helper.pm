package t::Helper;

use strict;
use warnings;

sub dist_data {
    return (
        {
            id           => 1,
            name         => 'Dist1',
            url          => 'https://github.com/perl6/modules.perl6.org/',
            description  => 'Test Dist1',
            author       => 'Dynacoder',
            has_tests    => 1,
            travis       => 'passing',
            stars        => 42,
            issues       => 12,
            date_updated => 1446999664,
            date_added   => 1446994664,
        },
        {
            id           => 2,
            name         => 'Dist2',
            url          => 'https://github.com/perl6/ecosystem/',
            description  => 'Test Dist2',
            author       => 'Morbo',
            has_tests    => 0,
            travis       => 'failing',
            stars        => 14,
            issues       => 6,
            date_updated => 1446990664,
            date_added   => 1446904664,
        },
    );
}

1;