#!perl

use strict;
use warnings FATAL => 'all';

use File::Temp;
use Test::Most;
use t::Helper;

use constant MODEL        => 'ModulesPerl6::Model::BuildStats';
use constant TEST_DB_FILE => File::Temp->new( UNLINK => 0, SUFFIX => '.db' );
END { unlink TEST_DB_FILE }

use_ok       MODEL;
my $m     =  MODEL->new( db_file => TEST_DB_FILE );
isa_ok $m => MODEL;
can_ok $m => qw/update  stats/;

isa_ok $m->deploy, MODEL, '->deploy returns invocant';

diag 'New stats';
isa_ok $m->update(qw/s1 v1  s2 v2  s3 v3/), MODEL,
    '->update returns invocant';
is_deeply $m->stats(qw/s1  s2  s3/), {qw/s1 v1  s2 v2  s3 v3/},
    'stats saved correctly';

diag 'Update stats';
ok $m->update(qw/s1 v2  s2 v2  s3 v3/), 'update existing';
is_deeply $m->stats(qw/s1  s2  s3/), {qw/s1 v2  s2 v2  s3 v3/},
    'stats updated correctly';

diag 'Delete stats';
isa_ok $m->update(map +( $_ => undef ), qw/s1 s2 not-there/),
    MODEL, '->delete returns invocant';

is_deeply $m->stats(qw/s1  s2  s3/), {s3 => 'v3'},
    'deleted correctly';

done_testing;
