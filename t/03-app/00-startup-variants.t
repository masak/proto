#!perl

use strict;
use warnings FATAL => 'all';
use File::Temp;
use Mojo::Util qw/spurt/;
use Test::Most;
use Test::Mojo::WithRoles qw/SubmitForm  ElementCounter  Debug/;
use t::Helper;
use experimental 'postderef';

my $db_file = t::Helper::setup_db_file;
END { unlink $db_file }

{   # exercise conditional branches not covered by other tests
    # For the secrets file: If tester has "secrets" file setup, other tests
    # will have tested the branch that tests its existence, so we'll set
    # the env to use a non-existant file and test that branch. Otherwise, we'll
    # create a temp file to use as secrets, and delete it when we're done.
    BEGIN {
        $ENV{MODULESPERL6_EXTRA_STATIC_PATH} = 't/03-app/public';
        $ENV{MODULESPERL6_SECRETS}           = -e 'secrets'
            ? 'non-existant'
            : File::Temp->new( UNLINK => 0 );

        $ENV{MOJO_MODE} = 'production';
    };
    END { -e 'secrets' or unlink $ENV{MODULESPERL6_SECRETS} };
    -e $ENV{MODULESPERL6_SECRETS}
        and spurt 's3crtz' => $ENV{MODULESPERL6_SECRETS};

    my $t = Test::Mojo::WithRoles->new('ModulesPerl6');
    $t->get_ok('/');

    subtest 'items_in helper' => sub {
        my $c = $t->app->build_controller;
        ok ! defined $c->items_in, 'returns undef for undef';
        $c->stash( foo => [42, 43] );
        is_deeply [$c->items_in('foo')      ], [42, 43],
            'works with stash vars';
        is_deeply [$c->items_in('not-there')], [      ],
            'works with not-found stash vars';
        is_deeply [$c->items_in( [42, 43] ) ], [42, 43],
            'works with actial arrayrefs';
    };
}

done_testing;
