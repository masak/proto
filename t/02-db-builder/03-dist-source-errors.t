#!perl

use strict;
use warnings FATAL => 'all';

use Pithub;
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

subtest 'JSON Parse errors' => sub {
    my @ar = (
        meta_url  => 'https://raw.githubusercontent.com/zoffixznet/'
                        . 'perl6-modules.perl6.org-test2/master/JSON.error',
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
            \Qhttps://raw.githubusercontent.com/zoffixznet/perl6-\E
            \Qmodules.perl6.org-test2/master/JSON.error\E \s
        $time_stamp_re\Q [info] Parsing META file\E \s
        $time_stamp_re\Q [error] Failed to parse: JSON error: malformed \E
            \QJSON string,\E .+? \Q"bar 42 lulz YOU GOT ...") \E
            \Qat /home/zoffix/perl5/perlbrew/perls/perl-5.22.0/lib/site_perl\E
            \Q/5.22.0/JSON/Meth.pm line 34.\E \s
    $}x, 'Output from says we got a JSON parse error';
};

subtest 'No dist name in META file' => sub {
    my @ar = (
        meta_url  => 'https://raw.githubusercontent.com/zoffixznet/perl6-'
                        . 'modules.perl6.org-test2/master/META.no-dist-name',
        logos_dir => $logos_dir,
        dist_db   => $m,
    );

    my $out = combined_from sub{
        my $dist = eval {
            ModulesPerl6::DbBuilder::Dist::Source::GitHub->new(@ar)->load
        } or do { print "Failed to get a dist! $@"; return; };
    };

    like $out, qr{
        $time_stamp_re\Q [info] Fetching distro info and commits\E \s
        $time_stamp_re\Q [info] Downloading META file from https://raw.\E
            \Qgithubusercontent.com/zoffixznet/perl6-modules.perl6.org-test2\E
            \Q/master/META.no-dist-name\E \s
        $time_stamp_re\Q [info] Parsing META file\E \s
        $time_stamp_re\Q [warn] Required `perl` field is missing\E \s
        $time_stamp_re\Q [warn] Required `name` field is missing\E \s
        \QFailed to get a dist!\E \s+
    $}x, 'Output matches expectations';

    is_deeply $m->find({name => 'N/A'})->to_array, [],
        'data in db matches expectations';
};

subtest 'Fail to get repo info through API' => sub {
    my @ar = (
        meta_url  => 'https://raw.githubusercontent.com/zoffixznet/'
                        . 'perl6-modules.perl6.org-test1/master/META.info',
        logos_dir => $logos_dir,
        dist_db   => $m,
        pithub => Pithub->new( # meddle with privates to simulate failure
            user => 'definitely-not-zoffix',
            repo => 'not valid repo',
        ),
    );

    my $dist;
    my $out = combined_from sub{
        $dist = eval {
            ModulesPerl6::DbBuilder::Dist::Source::GitHub->new(@ar)->load
        } or do { print "Failed to get a dist! $@"; return; };
    };

    like $out, qr{
        $time_stamp_re\Q [info] Fetching distro info and commits\E \s
        $time_stamp_re\Q [info] Downloading META file from https://raw.\E
            \Qgithubusercontent.com/zoffixznet/perl6-modules.perl6.org-\E
            \Qtest1/master/META.info\E \s
        $time_stamp_re\Q [info] Parsing META file\E \s
        $time_stamp_re\Q [warn] Required `perl` field is missing\E \s
        $time_stamp_re\Q [error] Error accessing GitHub API. \E
            \QHTTP Code: 404\E \s
        \QFailed to get a dist!\E \s
    $}x, 'Output matches expectations';
};

done_testing;
