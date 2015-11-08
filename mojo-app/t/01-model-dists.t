#!perl

use strict;
use warnings FATAL => 'all';
use Test::Most;
use Mojo::SQLite;

use constant TEST_DB_FILE => 'test-01-model.db'; END { unlink TEST_DB_FILE; }
use constant MODEL        => 'ModulesPerl6::Model::Dists';

use_ok       MODEL;
my $m     =  MODEL->new( db_file => TEST_DB_FILE );
isa_ok $m => MODEL;
can_ok $m => qw/add   remove   find/;

my ( $dist1, $dist2 ) = dist_data();

isa_ok $m->add( $dist1, $dist2 ), MODEL, '->add returns invocant';

isa_ok $m->find, 'Mojo::Collection', '->find returns Mojo::Collection object';
is_deeply $m->find, [$dist1, $dist2],
    '->find with no arguments returns all dists';

throws_ok { $m->find('not a hashref') } qr/find only accepts a hashref/,
    'complaining when not giving correct args';

is_deeply $m->find({name => '42'}), [], 'empty list when nothing found';

subtest 'Testing find by...' => sub {
    is_deeply $m->find({ name   => 'Dist1'      }), [$dist1], 'name, string'  ;
    is_deeply $m->find({ name   => qr/2/        }), [$dist2], 'name, regex'   ;

    is_deeply $m->find({ author => 'Dynacoder'  }), [$dist1], 'author, string';
    is_deeply $m->find({ author => qr/Morb/     }), [$dist2], 'author, regex' ;

    is_deeply $m->find({ travis => 'passing'    }), [$dist1], 'travis, string';
    is_deeply $m->find({ travis => qr/failing/  }), [$dist2], 'travis, regex' ;

    is_deeply $m->find({ description => 'Test Dist 1'}), [$dist1],
        'description, string';
    is_deeply $m->find({ description => qr/2/        }), [$dist2],
        'description, regex';

    is_deeply $m->find({ name => 'Dist1', author => qr/Dyna/ }), [$dist1],
        'name and author (combined)';

    is_deeply $m->find({ name => 'Dist1', author => qr/Morb/ }), [],
        'name and author (combined; should get no results)';

    done_testing;
};

isa_ok    $m->remove(1),                  MODEL,   '->remove returns invocant';
is_deeply $m->find,                      [$dist2], 'removed a dist';
is_deeply $m->find({ name => 'Dist1 '}), [],       'and it is no longer found';

done_testing;

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
            issues       => 12
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
