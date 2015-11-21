#!perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use t::Helper;

use constant MODEL         => 'ModulesPerl6::Model::SiteTips';
use constant TEST_TIP_FILE => 't/01-models/03-site-tips-TEST-TIPS.txt';

-r TEST_TIP_FILE
    or BAIL_OUT 'Could not find test tip file at ' . TEST_TIP_FILE;

use_ok       MODEL;
my $m     =  MODEL->new( tip_file => TEST_TIP_FILE );
isa_ok $m => MODEL;
can_ok $m => qw/tip  tip_file/;

is $m->tip_file, TEST_TIP_FILE, '->tip_file gives correct results';

my $is_wrong = 0;
diag 'Fetching tips many times...';
$m->tip =~ /^Tip \d\z/ or $is_wrong = 1 for 1 .. 2_000_000;
is $is_wrong, 0, '... all fetches were correct';

done_testing;
