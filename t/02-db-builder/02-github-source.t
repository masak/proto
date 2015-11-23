#!perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use Test::Output qw/combined_from/;
use t::Helper;
use File::Temp qw/tempdir/;
use ModulesPerl6::Model::Dists;
BEGIN { use_ok 'DbBuilder::Dist::Source::GitHub' };

my $db_file = t::Helper::setup_db_file;
END { unlink $db_file };

my $m = ModulesPerl6::Model::Dists->new( db_file => $db_file );
my $logos_dir = tempdir CLEANUP => 1;
my $time_stamp_re = qr/\[\w{3} \w{3} \d\d? \d{2}:\d{2}:\d{2} \d{4}\]/;

subtest 'Repo without a README, tests, or logotype' => sub {
    my @ar = (
        meta_url  => 'https://raw.githubusercontent.com/zoffixznet/'
                        . 'perl6-modules.perl6.org-test1/master/META.info',
        logos_dir => $logos_dir,
        dist_db   => $m,
    );

    my $out = combined_from sub{
        my $dist = eval { DbBuilder::Dist::Source::GitHub->new(@ar)->load }
            or do { print "Failed to get a dist! $@"; return; };
        $dist->{build_id} = 42;
        $m->add( $dist );
    };
    like $out, qr{
        $time_stamp_re\Q [info] Fetching distro info and commits\E \s
        $time_stamp_re\Q [info] Downloading META file from \E
        \Qhttps://raw.githubusercontent.com/zoffixznet/perl6-modules.perl6.\E
        \Qorg-test1/master/META.info\E \s
        $time_stamp_re\Q [info] Parsing META file\E \s
        $time_stamp_re\Q [warn] Required `perl` field is missing\E \s
        $time_stamp_re\Q [info] Dist has new commits. Fetching more info.\E \s
    $}x, 'Output from loader matches';

    $out = combined_from sub{
        my $dist = eval { DbBuilder::Dist::Source::GitHub->new(@ar)->load }
            or do { print "Failed to get a dist! $@"; return; };
        $dist->{build_id} = 42;
        $m->add( $dist );
    };
    like $out, qr{
        $time_stamp_re\Q [info] Fetching distro info and commits\E \s
        $time_stamp_re\Q [info] Downloading META file from \E
        \Qhttps://raw.githubusercontent.com/zoffixznet/perl6-modules.perl6.\E
        \Qorg-test1/master/META.info\E \s
        $time_stamp_re\Q [info] Parsing META file\E \s
        $time_stamp_re\Q [warn] Required `perl` field is missing\E \s
    $}x, 'Loading same dist again; must not get "has new commits" message';

    diag 'Check data in the db';
    is_deeply $m->find({name => 'TestRepo1'})->first, {
        date_added    => 0,
        author_id     => 'Zoffix Znet',
        logo          => 'N_A',
        name          => 'TestRepo1',
        kwalitee      => 100,
        date_updated  => 1448202981,
        issues        => 2,
        travis_status => 'not set up',
        stars         => 1,
        url           => 'https://api.github.com/repos/zoffixznet/perl6-'
                            . 'modules.perl6.org-test1',
        build_id      => '42',
        description   => 'Test repo for modules.perl6.org: Single-commit '
                            . 'repo / lack of README, tests, and logotypes'
    };
};

done_testing;