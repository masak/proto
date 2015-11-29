#!perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
BEGIN { use_ok 'ModulesPerl6::DbBuilder::Dist::PostProcessor' };

can_ok 'ModulesPerl6::DbBuilder::Dist::PostProcessor',
    qw/new  _dist  _meta_url  process/;

my $p = ModulesPerl6::DbBuilder::Dist::PostProcessor->new(
    dist => {},
    meta_url => '42',
);

throws_ok { $p->process } qr/Unimplemented/, '->process throws unimplemented';

done_testing;
