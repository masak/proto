package t::Helper;

use strict;
use warnings;

sub set_db_env {
    my $db_file = 't/test.db';
    $ENV{MODULESPERL6_DB_FILE} = $db_file;

    -r $db_file
        or die 'Could not find test database ' . $db_file
        . '. Perhaps, you are running this test in a wrong directory?';

    return $db_file;
}

sub dist_data {
    return (
        {
            id           => 1,
            name         => 'Dist1',
            url          => 'https://github.com/perl6/modules.perl6.org/',
            description  => 'Test Dist1',
            author       => 'Dynacoder',
            logo         => 'dist1.png',
            has_readme   => 1,
            panda        => 2,
            has_tests    => 1,
            travis       => 'passing',
            stars        => 42,
            issues       => 12,
            date_updated => 1446999664,
            date_added   => 1446694664,
        },
        {
            id           => 2,
            name         => 'Dist2',
            url          => 'https://github.com/perl6/ecosystem/',
            description  => 'Test Dist2',
            author       => 'Morbo',
            logo         => 'dist2.png',
            has_readme   => 0,
            panda        => 0,
            has_tests    => 0,
            travis       => 'failing',
            stars        => 14,
            issues       => 6,
            date_updated => 1446490664,
            date_added   => 1445904664,
        },
    );
}

1;