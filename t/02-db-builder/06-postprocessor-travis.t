#!perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use Test::Output qw/combined_from/;
use t::Helper;
BEGIN { use_ok 'ModulesPerl6::DbBuilder::Dist::PostProcessor::TravisCI' };

my $time_stamp_re = t::Helper::time_stamp_re;

subtest 'Bailout if dist does not have date_updated' => sub {
    my $travis = ModulesPerl6::DbBuilder::Dist::PostProcessor::TravisCI->new(
        dist => {},
        meta_url => 'fake-url',
    );

    is_deeply [$travis->process], [], 'bailed';
};

subtest q{Bailout if dist's last commit was over 24 hours ago} => sub {
    my $travis = ModulesPerl6::DbBuilder::Dist::PostProcessor::TravisCI->new(
        dist => { date_updated => time - 60*60*25 },
        meta_url => 'fake-url',
    );

    is_deeply [$travis->process], [], 'bailed';
};

subtest 'Bailout if dist does not have travis enabled' => sub {
    my $travis = ModulesPerl6::DbBuilder::Dist::PostProcessor::TravisCI->new(
        dist => { date_updated => time, _builder => {} },
        meta_url => 'fake-url',
    );

    is_deeply [$travis->process], [], 'bailed';
};

subtest 'Bailout if dist did not provide repo_user and repo name' => sub {
    my $travis = ModulesPerl6::DbBuilder::Dist::PostProcessor::TravisCI->new(
        dist => { date_updated => time, _builder => { has_travis => 1 } },
        meta_url => 'fake-url',
    );
    is_deeply [$travis->process], [], 'bailed on neither';

    $travis = ModulesPerl6::DbBuilder::Dist::PostProcessor::TravisCI->new(
        dist => {
            date_updated => time,
            _builder => { has_travis => 1, repo_user => 'zoffixznet',}
        },
        meta_url => 'fake-url',
    );
    is_deeply [$travis->process], [], 'bailed repo_user only';

    $travis = ModulesPerl6::DbBuilder::Dist::PostProcessor::TravisCI->new(
        dist => {
            date_updated => time,
            _builder => { has_travis => 1, repo => '42',}
        },
        meta_url => 'fake-url',
    );
    is_deeply [$travis->process], [], 'bailed repo only';
};

subtest 'Find Travis build status' => sub {
    my $travis = ModulesPerl6::DbBuilder::Dist::PostProcessor::TravisCI->new(
        dist => {
            date_updated => time,
            _builder => {
                has_travis => 1,
                repo_user => 'zoffixznet',
                repo => 'perl6-Color',
            },
        },
        meta_url => 'https://raw.githubusercontent.com/zoffixznet/perl6'
                        . '-Color/master/META.info',
    );

    is $travis->process, 1, '->process worked fine';

    like $travis->_dist->{travis_status},
        qr/unknown|cancell?ed|pending|error|failing|passing/,
        'set travis status looks sane';
};

subtest q{Do NOT bailout if dist's last commit was over 24 hours ago}
    . q{, but cached Travis status is "unknown"} => sub {
    my $travis = ModulesPerl6::DbBuilder::Dist::PostProcessor::TravisCI->new(
        dist => {
            travis_status => 'unknown',
            date_updated => time - 60*60*25,
            _builder => {
                has_travis => 1,
                repo_user => 'zoffixznet',
                repo => 'perl6-Color',
            },
        },
        meta_url => 'https://raw.githubusercontent.com/zoffixznet/perl6'
                        . '-Color/master/META.info',
    );

    is $travis->process, 1, '->process worked fine';

    like $travis->_dist->{travis_status},
        qr/unknown|cancell?ed|pending|error|failing|passing/,
        'set travis status looks sane';
};

done_testing;
