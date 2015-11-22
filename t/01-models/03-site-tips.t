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
can_ok $m => qw/tip/;

subtest 'Fetching tips many times...' => sub {
    my $is_wrong = 0;
    my %seen_tips;
    for ( 1 .. 2_000_000 ) {
        my $tip = $m->tip;
        $tip =~ /^Tip \d\z/ or $is_wrong = 1;
        $seen_tips{ $tip } = 1;
    }
    is $is_wrong, 0, '... all fetches were correct';

    if ( 2 > keys %seen_tips ) {
        warn 'We got fewer than 2 tips. It might indicate a problem with code';
    }
    elsif ( 2 < keys %seen_tips ) {
        fail 'More than 2 tips were seen. That must not happen'
    }

    diag "Seen these tips: " . join ', ', sort keys %seen_tips;
};

done_testing;
