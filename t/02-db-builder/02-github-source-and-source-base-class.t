#!perl

use strict;
use warnings FATAL => 'all';
use utf8;

use File::Spec::Functions qw/catfile/;
use Test::Most;
use Test::Output qw/combined_from/;
use t::Helper;
use File::Temp qw/tempdir/;
use ModulesPerl6::Model::Dists;
use ModulesPerl6::DbBuilder::Dist;
BEGIN { use_ok 'ModulesPerl6::DbBuilder::Dist::Source'         };
BEGIN { use_ok 'ModulesPerl6::DbBuilder::Dist::Source::GitHub' };

my $db_file = t::Helper::setup_db_file;
END { unlink $db_file };

my $m = ModulesPerl6::Model::Dists->new( db_file => $db_file );
my $logos_dir = tempdir CLEANUP => 1;
my $time_stamp_re = t::Helper::time_stamp_re;

subtest 'Not overridden methods from baseclass' => sub {
    my $s = ModulesPerl6::DbBuilder::Dist::Source->new(
        meta_url  => 'https://raw.githubusercontent.com/zoffixznet/'
                  . 'perl6-modules.perl6.org-test1/master/META.info-no-author',
        logos_dir => $logos_dir,
        dist_db   => $m,
    );
    throws_ok { $s->load } qr/Unimplemented/, '->load throws';
    throws_ok { $s->re   } qr/Unimplemented/, '->re throws';
};

subtest 'Private methods' => sub {
    my $s = ModulesPerl6::DbBuilder::Dist::Source->new(
        meta_url  => 'https://raw.githubusercontent.com/zoffixznet/'
                  . 'perl6-modules.perl6.org-test1/master/META.info-no-author',
        logos_dir => $logos_dir,
        dist_db   => $m,
        dist      => { my => 'test-dist'},
    );

    $s->_set_readme( qw/foo/ );
    $s->_set_tests(  qw/foo/ );
    is_deeply $s->_dist, {my => 'test-dist', has_tests => 0, has_readme => 0},
        'tests/readme are NOT set when files are not present';

    $s->_set_readme( qw/foo README bar/ );
    $s->_set_tests(  qw/foo tests  bar/ );
    is_deeply $s->_dist, {my => 'test-dist', has_tests => 1, has_readme => 1},
        'tests/readme are set when files are present';

    is $s->_get_author({author => 'zoffix'}),
        'zoffix', 'get author ID from `author` key set to string';
    is $s->_get_author({author => ['zoffix', 'not zoffix']}),
        'zoffix', 'get author ID from `author` key set to arrayref';
    is $s->_get_author({authors => 'zoffix'}),
        'zoffix', 'get author ID from `authors` key set to string';
    is $s->_get_author({authors => ['zoffix', 'not zoffix']}),
        'zoffix', 'get author ID from `authors` key set to arrayref';
    is $s->_get_author({}), 'N/A', 'no author[s] key is present';
};

subtest 'Repo without a README, tests, or logotype' => sub {
    my @ar = (
        meta_url  => 'https://raw.githubusercontent.com/zoffixznet/'
                        . 'perl6-modules.perl6.org-test1/master/META.info',
        logos_dir => $logos_dir,
        dist_db   => $m,
    );

    my $out = combined_from sub{
        my $dist = eval {
            ModulesPerl6::DbBuilder::Dist::Source::GitHub->new(@ar)->load
        } or do { print "Failed to get a dist! $@"; return; };
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
        my $dist = eval {
            ModulesPerl6::DbBuilder::Dist::Source::GitHub->new(@ar)->load
        } or do { print "Failed to get a dist! $@"; return; };
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

    is_deeply $m->find({name => 'TestRepo1'})->first, {
        date_added    => 0,
        author_id     => 'Zoffix Znet',
        name          => 'TestRepo1',
        koalatee      => 60,
        date_updated  => 1448665634,
        issues        => 2,
        travis_status => 'not set up',
        stars         => 1,
        meta_url      => 'https://raw.githubusercontent.com/zoffixznet/'
                            . 'perl6-modules.perl6.org-test1/master/META.info',
        url           => 'https://github.com/zoffixznet/perl6-'
                            . 'modules.perl6.org-test1',
        build_id      => '42',
        description   => 'Test dist for modules.perl6.org build script'
    }, 'data in db matches expectations';
    $m->remove({name => 'TestRepo1'});
};

subtest 'Repo without an author field' => sub {
    my @ar = (
        meta_url  => 'https://raw.githubusercontent.com/zoffixznet/'
                  . 'perl6-modules.perl6.org-test1/master/META.info-no-author',
        logos_dir => $logos_dir,
        dist_db   => $m,
    );

    my $dist;
    my $out = combined_from sub{
        $dist = eval {
            ModulesPerl6::DbBuilder::Dist::Source::GitHub->new(@ar)->load
        } or do { print "Failed to get a dist! $@"; return; };
    };

    like $out, qr{
        $time_stamp_re\Q [info] Fetching distro info and commits\E \s
        $time_stamp_re\Q [info] Downloading META file from \E
        \Qhttps://raw.githubusercontent.com/zoffixznet/perl6-modules.perl6.\E
        \Qorg-test1/master/META.info-no-author\E \s
        $time_stamp_re\Q [info] Parsing META file\E \s
        $time_stamp_re\Q [warn] Required `perl` field is missing\E \s
        $time_stamp_re\Q [info] Dist has new commits. Fetching more info.\E \s
    $}x, 'Output from loader matches';

    is $dist->{_builder}{repo_user}, 'zoffixznet', 'repo user is correct';
    is $dist->{author_id},           'zoffixznet', 'author_id is correct';
};

subtest 'Downloading logotype' => sub {
    my @ar = (
        meta_url  => 'https://raw.githubusercontent.com/zoffixznet/'
                        . 'perl6-modules.perl6.org-test3/master/META.info',
        logos_dir => $logos_dir,
        dist_db   => $m,
    );

    my $out = combined_from sub{
        eval {
            ModulesPerl6::DbBuilder::Dist::Source::GitHub->new(@ar)->load
        } or do { print "Failed to get a dist! $@"; return; };
    };

    like $out, qr{
        $time_stamp_re\Q [info] Fetching distro info and commits\E \s
        $time_stamp_re\Q [info] Downloading META file from \E
        \Qhttps://raw.githubusercontent.com/zoffixznet/perl6-modules.perl6.\E
        \Qorg-test3/master/META.info\E \s
        $time_stamp_re\Q [info] Parsing META file\E \s
        $time_stamp_re\Q [warn] Required `perl` field is missing\E \s
        $time_stamp_re\Q [info] Dist has new commits. Fetching more info.\E \s
        $time_stamp_re\Q [info] Dist has a logotype of size 160 bytes.\E \s
        $time_stamp_re\Q [info] Did not find cached dist logotype. \E
            \QDownloading.\E \s
    $}x, 'Output from loader matches';

    ok -e catfile($logos_dir, 's-TestRepo3.png'), 'logo file was downloaded';
    is -s catfile($logos_dir, 's-TestRepo3.png'), 160, 'size of logo matches';

    diag 'Try again; we must not re-download logotype';
    $out = combined_from sub{
        eval {
            ModulesPerl6::DbBuilder::Dist::Source::GitHub->new(@ar)->load
        } or do { print "Failed to get a dist! $@"; return; };
    };

    like $out, qr{
        $time_stamp_re\Q [info] Fetching distro info and commits\E \s
        $time_stamp_re\Q [info] Downloading META file from \E
        \Qhttps://raw.githubusercontent.com/zoffixznet/perl6-modules.perl6.\E
        \Qorg-test3/master/META.info\E \s
        $time_stamp_re\Q [info] Parsing META file\E \s
        $time_stamp_re\Q [warn] Required `perl` field is missing\E \s
        $time_stamp_re\Q [info] Dist has new commits. Fetching more info.\E \s
        $time_stamp_re\Q [info] Dist has a logotype of size 160 bytes.\E \s
    $}x, 'Output from loader matches';
};

subtest 'Mojibake from utf-8 in META file (Issue #48)' => sub {
    my $dist = ModulesPerl6::DbBuilder::Dist::Source::GitHub->new(
        meta_url  => 'https://raw.githubusercontent.com/zoffixznet/'
                  . 'perl6-modules.perl6.org-test2/master/META.utf8',
        logos_dir => $logos_dir,
        dist_db   => $m,
    )->load;

    is $dist->{name}, 'テスト', 'Unicode chars in name look right';
    is $dist->{description}, 'テストdist for modules.perl6.org build script',
        'Unicode chars in name look right';
};

subtest 'Ensure we do find all the Koalatee metrics' => sub {
    my $meta_url = 'https://raw.githubusercontent.com/zoffixznet/perl6'
                        . '-Color/master/META.info';
    my $dist = ModulesPerl6::DbBuilder::Dist::Source::GitHub->new(
        meta_url  => $meta_url,
        logos_dir => $logos_dir,
        dist_db   => $m,
    )->load;

    for my $postprocessor ( ModulesPerl6::DbBuilder::Dist->_postprocessors ) {
        $postprocessor->new(
            meta_url => $meta_url,
            dist     => $dist,
        )->process;
    }

    is $dist->{has_readme},    1,         'README found';
    is $dist->{has_tests},     1,         'tests found';
    is $dist->{panda},         2,         'panda conformance is correct';
    is $dist->{travis_status}, 'passing', 'Travis status is correct';
};

subtest 'Do not operate on weird URLs, even if they are on GitHub' => sub {
    unlike 'https://raw.githubusercontent.com/perl6/ecosystem'
        . '/master/SHELTER/lolsql/META.info',
        ModulesPerl6::DbBuilder::Dist::Source::GitHub->re,
        'Weird URL must not match GitHub Dist Source';
};


done_testing;
