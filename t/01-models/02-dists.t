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

{
    # Modify input data; second ->add should update it back to original
    # returned from ::dist_in_data
    my @d = t::Helper::dist_in_data;
    $d[1]{build_id} = 'rvOZAHmQ5RGKE79B+wjaYA==';
    isa_ok $m->add( @d ), MODEL, '->add returns invocant';
    isa_ok $m->add,       MODEL, '->add without arguments returns invocant';

    diag 'Adding same data to database again. '
        . 'It must not be duplicated and must instead only be updated';
    $m->add( t::Helper::dist_in_data );
}

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

throws_ok { $m->remove_old } qr/Missing Build ID to keep/,
    '->remove_old has correct error when called without a build ID';
is $m->remove_old('rvOZAHmQ5RGKE79B+wjaYA=='), 1,
    '->remove_old returns invocant';
is_deeply $m->find, [],
    'remove_old tossed dists that did not have correct build ID';

subtest 'Test salvage_build method' => sub {
    $m->add( t::Helper::dist_in_data );
    is_deeply $m->find, [$dist1, $dist2], 're-add dists into database';

    is_deeply [$m->salvage_build], [],
        '->salvage_build returns empty list without correct args';
    is_deeply [$m->salvage_build('fake-url')], [],
        '->salvage_build returns empty list without correct args';

    is $m->salvage_build( $dist1->{url}, 'new-build-id'), 1,
        '->salvage_build with correct arguments returns 1';

    is $m->remove_old('new-build-id'), 1,
        'purge all dists with old build ID; that should delete one dist';

    my %mod_dist1 = ( %$dist1, build_id => 'new-build-id' );
    is_deeply $m->find, [\%mod_dist1], 'correct dists remain in the database';
};

done_testing;
