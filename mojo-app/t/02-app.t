#!perl

use strict;
use warnings FATAL => 'all';
use Test::Most;
use Test::Mojo;
use t::Helper;

use constant TEST_DB_FILE => 't/test.db';
$ENV{MODULESPERL6_DB_FILE} = TEST_DB_FILE;

-r TEST_DB_FILE
    or die 'Could not find test database ' . TEST_DB_FILE
    . '. Perhaps, you are running this test in a wrong directory?';

my $t = Test::Mojo->new('ModulesPerl6');

{
    $t->get_ok('/')->status_is(200)
}

done_testing;

