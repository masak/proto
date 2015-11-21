#!perl

use strict;
use warnings FATAL => 'all';

use File::Temp;
use Test::Most;
use t::Helper;

use constant MODEL        => 'ModulesPerl6::Model::Dists';
use constant TEST_DB_FILE => File::Temp->new( UNLINK => 0, SUFFIX => '.db' );
END { unlink TEST_DB_FILE }

use_ok       MODEL;
my $m     =  MODEL->new( db_file => TEST_DB_FILE );
isa_ok $m => MODEL;
can_ok $m => qw/add   deploy  find  remove  remove_old/;

my ( $dist1, $dist2 ) = t::Helper::dist_out_data;

isa_ok $m->deploy,                         MODEL, '->deploy returns invocant';
isa_ok $m->add( t::Helper::dist_in_data ), MODEL, '->add    returns invocant';

isa_ok $m->find, 'Mojo::Collection', '->find returns Mojo::Collection object';
is_deeply $m->find, [$dist1, $dist2],
    '->find with no arguments returns all dists';

throws_ok { $m->find('not a hashref') } qr/find only accepts a hashref/,
    'complaining when not giving correct args';

is_deeply $m->find({name => '42'}), [], 'empty list when nothing found';

subtest 'Testing find by...' => sub {
    is_deeply $m->find({ name   => 'Dist1'      }), [$dist1], 'name, string'  ;
    is_deeply $m->find({ name   => \2        }), [$dist2], 'name, partial'   ;

    is_deeply $m->find({ author_id => 'Dynacoder'  }), [$dist1], 'author, string';
    is_deeply $m->find({ author_id => \'Morb'     }), [$dist2], 'author, parial' ;

    is_deeply $m->find({ travis_status => 'passing'    }), [$dist1], 'travis, string';
    is_deeply $m->find({ travis_status => \'failing'  }), [$dist2], 'travis, partial' ;

    is_deeply $m->find({ description => 'Test Dist1'}), [$dist1],
        'description, string';
    is_deeply $m->find({ description => \'2'        }), [$dist2],
        'description, regex';

    is_deeply $m->find({ name => 'Dist1', author_id => \'Dyna' }), [$dist1],
        'name and author (combined)';

    is_deeply $m->find({ name => 'Dist1', author_id => \'Morb' }), [],
        'name and author (combined; should get no results)';

    done_testing;
};

isa_ok   $m->remove({ name => 'Dist1'}), MODEL,   '->remove returns invocant';
is_deeply $m->find,                      [$dist2], 'removed a dist';
is_deeply $m->find({ name => 'Dist1'}),  [],       'and it is no longer found';

isa_ok $m->remove_old('rvOZAHmQ5RGKE79B+wjaYA=='), MODEL,
    '->remove_old returns invocant';
is_deeply $m->find, [],
    'remove_old tossed dists that did not have correct build ID';

done_testing;
