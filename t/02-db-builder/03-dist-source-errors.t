#!perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use Test::Output qw/combined_from/;
use t::Helper;
use File::Temp qw/tempdir/;
use ModulesPerl6::Model::Dists;
BEGIN { use_ok 'ModulesPerl6::DbBuilder::Dist::Source::GitHub' };

my $db_file = t::Helper::setup_db_file;
END { unlink $db_file };

my $m = ModulesPerl6::Model::Dists->new( db_file => $db_file );
my $logos_dir = tempdir CLEANUP => 1;
my $time_stamp_re = qr/\[\w{3} \w{3} \d\d? \d{2}:\d{2}:\d{2} \d{4}\]/;

subtest '404 on META file' => sub {
    my @ar = (
        meta_url  => 'http://httpbin.org/status/404',
        logos_dir => $logos_dir,
        dist_db   => $m,
    );

    my $out = combined_from sub{
        eval { ModulesPerl6::DbBuilder::Dist::Source::GitHub->new(@ar)->load };
        $@ and print "Fatal error occured: $@";
    };

    like $out, qr{
        $time_stamp_re\Q [info] Fetching distro info and commits\E \s
        $time_stamp_re\Q [info] Downloading META file from \E
            \Qhttp://httpbin.org/status/404\E \s
        $time_stamp_re\Q [error] 404 response: NOT FOUND\E \s
    $}x, 'Output from says we got a 404';
};

subtest 'Unreachable resource (NOTE: tries connecting to localhost:1)' => sub {
    my @ar = (
        meta_url  => 'http://localhost:1',
        logos_dir => $logos_dir,
        dist_db   => $m,
    );

    my $out = combined_from sub{
        eval { ModulesPerl6::DbBuilder::Dist::Source::GitHub->new(@ar)->load };
        $@ and print "Fatal error occured: $@";
    };

    like $out, qr{
        $time_stamp_re\Q [info] Fetching distro info and commits\E \s
        $time_stamp_re\Q [info] Downloading META file from \E
            \Qhttp://localhost:1\E \s
        $time_stamp_re\Q [error] Connection error: Connection refused\E \s
    $}x, 'Output from says we got a 404';
};

done_testing;