package t::Helper;

use strict;
use warnings FATAL => 'all';
use ModulesPerl6::Model::Dists;
use File::Temp;

sub setup_db_file {
    my $db_file = File::Temp->new( UNLINK => 0, SUFFIX => '.db' );
    $ENV{MODULESPERL6_DB_FILE} = $db_file;

    ModulesPerl6::Model::Dists->new( db_file => $db_file )
        ->deploy->add( dist_in_data() );

    return $db_file;
}

sub dist_in_data {
    return (
        {
            name         => 'Dist1',
            url          => 'https://github.com/perl6/modules.perl6.org/',
            description  => 'Test Dist1',
            author_id    => 'Dynacoder',
            logo         => 'dist1',
            has_readme   => 1,
            panda        => 2,
            has_tests    => 1,
            travis_status=> 'passing',
            stars        => 42,
            issues       => 12,
            date_updated => 1446999664,
            date_added   => 1446694664,
        },
        {
            name         => 'Dist2',
            url          => 'https://github.com/perl6/ecosystem/',
            description  => 'Test Dist2',
            author_id    => 'Morbo',
            logo         => 'dist2',
            has_readme   => 0,
            panda        => 0,
            has_tests    => 0,
            travis_status=> 'failing',
            stars        => 14,
            issues       => 6,
            date_updated => 1446490664,
            date_added   => 1445904664,
        },
    );
}

sub dist_out_data {
    return (
        {
            name         => 'Dist1',
            url          => 'https://github.com/perl6/modules.perl6.org/',
            description  => 'Test Dist1',
            author_id    => 'Dynacoder',
            logo         => 'dist1',
            kwalitee     => 100,
            travis_status=> 'passing',
            stars        => 42,
            issues       => 12,
            date_updated => 1446999664,
            date_added   => 1446694664,
        },
        {
            name         => 'Dist2',
            url          => 'https://github.com/perl6/ecosystem/',
            description  => 'Test Dist2',
            author_id    => 'Morbo',
            logo         => 'dist2',
            kwalitee     => 100,
            travis_status=> 'failing',
            stars        => 14,
            issues       => 6,
            date_updated => 1446490664,
            date_added   => 1445904664,
        },
    );
}

1;