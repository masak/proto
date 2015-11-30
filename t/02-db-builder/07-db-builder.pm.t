#!perl

use strict;
use warnings FATAL => 'all';

use Mojo::Util qw/spurt  trim/;
use Test::Most;
use Test::Output qw/combined_from/;
use t::Helper;
use File::Temp qw/tempdir/;
use ModulesPerl6::Model::Dists;
use experimental 'postderef';
BEGIN { use_ok 'ModulesPerl6::DbBuilder' };

my $db_file = t::Helper::setup_db_file;
END { unlink $db_file };

my $m = ModulesPerl6::Model::Dists->new( db_file => $db_file );
my $logos_dir = tempdir CLEANUP => 1;
my $re = t::Helper::time_stamp_re;

subtest 'failing dist build (META file fetch fail)' => sub {
    my $meta_list = File::Temp->new;
    spurt "https://raw.githubusercontent.com/zoffixznet/"
        . "perl6-Color/master/META.info\nhttp://raw.githubusercontent"
        . ".com/localhost/1\n"
    => $meta_list;

    $m->remove({ name => 'Dist1' }); # remove one dist inited by t::Helper
    my ( $other_dist ) = t::Helper::dist_in_data;
    $other_dist->{meta_url} = 'http://raw.githubusercontent.com/localhost/1';
    $m->add( $other_dist );

    my $out = combined_from sub {
        my $b = ModulesPerl6::DbBuilder->new(
            app         => 'whatever',
            db_file     => $db_file->filename,
            interval    => 0,
            limit       => undef,
            logos_dir   => $logos_dir,
            meta_list   => $meta_list->filename,
            restart_app => 0,
        )->run;
    };

    my ( $build_id ) = $out =~ /Starting build (\S+)/;

    my @dists = $m->find->to_array->@*;
    is scalar(@dists), 2, 'still have 2 dists in db';
    is $dists[0]{build_id}, $build_id, 'build ID on dist 1 was updated';
    is $dists[1]{build_id}, $build_id, 'build ID on dist 2 was updated';

    my @out = map trim($_), split /---/, $out;
    like $out[0], qr{^
        $re\Q [info] Starting build $build_id\E \s
        $re\Q [info] Using database file $db_file\E \s
        $re\Q [info] Will be saving images to $logos_dir\E \s
        $re\Q [info] Loading META.list from $meta_list\E \s
        $re\Q [info] ... a file detected; trying to read\E \s
        $re\Q [info] Found 2 dists\E
    $}x, 'part 0 of output matches';

    like $out[1], qr{^
        $re\Q [info] Processing dist 1 of 2\E \s
        $re\Q [info] Using ModulesPerl6::DbBuilder::Dist::Source::GitHub to \E
            \Qload https://raw.githubusercontent.com/zoffixznet/perl6-Color/\E
            \Qmaster/META.info\E \s
        $re\Q [info] Fetching distro info and commits\E \s
        $re\Q [info] Downloading META file from https://raw.githubusercontent\E
            \Q.com/zoffixznet/perl6-Color/master/META.info\E \s
        $re\Q [info] Parsing META file\E \s
        $re\Q [warn] Required `perl` field is missing\E \s
        $re\Q [info] Dist has new commits. Fetching more info.\E \s
        $re\Q [info] Dist has a logotype of size 1390 bytes.\E \s
        $re\Q [info] Did not find cached dist logotype. Downloading.\E \s
        $re\Q [info] Determined travis status is \E ([a-z]+)
    $}x, , 'part 1 of output matches';

    like $out[2], qr{^
        $re\Q [info] Processing dist 2 of 2\E \s
        $re\Q [info] Using ModulesPerl6::DbBuilder::Dist::Source::GitHub \E
            \Qto load http://raw.githubusercontent.com/localhost/1\E \s
        $re\Q [info] Fetching distro info and commits\E \s
        $re\Q [info] Downloading META file from http://raw.githubusercontent\E
            \Q.com/localhost/1\E \s
        $re\Q [error] 400 response: Bad Request\E \s
        $re\Q [error] Received fatal error while building http://raw.\E
            \Qgithubusercontent.com/localhost/1: Failed to build dist\E
    $}x, , 'part 2 of output matches';

    like $out[3], qr{^
    $}x, , 'part 3 of output matches';

    like $out[4], qr{^
        $re\Q [info] Finished building all dists. Performing cleanup.\E \s
        $re\Q [info] Removed 1 dists that are no longer in the ecosystem\E \s
        $re\Q [info] Finished build $build_id\E
    $}x, , 'part 4 of output matches';
};

done_testing;
