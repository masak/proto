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

{
    diag 'To properly run this test, do `rm public/content-pics/dist-logos/*`.'
            . ' Because otherwise, coverage is not 100%';

    BEGIN {
        $ENV{MODULESPERL6_EXTRA_STATIC_PATH} = 't/03-app/public';
        $ENV{MODULESPERL6_SECRETS}           = File::Temp->new( UNLINK => 0 );
        $ENV{MOJO_MODE} = 'production';
    };
    END { unlink $ENV{MODULESPERL6_SECRETS} };
    spurt 's3crtz' => $ENV{MODULESPERL6_SECRETS};

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
