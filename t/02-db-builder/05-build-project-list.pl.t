#!perl

use strict;
use warnings FATAL => 'all';

use File::Temp qw/tempdir/;
use Mojo::Util qw/spurt  trim/;
use Test::Most;
use Test::Script;
use t::Helper;

use ModulesPerl6::Model::Dists;
BEGIN { use_ok 'ModulesPerl6::DbBuilder::Dist' };

my $db_file = t::Helper::setup_db_file;
END { unlink $db_file };

my $logos_dir = tempdir CLEANUP => 0;
my $re = t::Helper::time_stamp_re;
my $meta_list = File::Temp->new;

spurt get_meta_list() => $meta_list;

diag 'Running build on 4 dists (might take a while)';
my $out;
script_runs [
    'bin/build-project-list.pl',
    '--interval=0',
    "--meta-list=$meta_list",
    "--db-file=$db_file",
    "--logos-dir=$logos_dir",
], { stdout => \$out, stderr => \$out };

my @out = map trim($_), split /---/, $out;
like $out[0], qr{^
    $re\Q [info] Starting build \E ([\w=]{12,30}) \s
    $re\Q [info] Using database file $db_file\E \s
    $re\Q [info] Will be saving images to $logos_dir\E \s
    $re\Q [info] Loading META.list from $meta_list\E \s
    $re\Q [info] ... a file detected; trying to read\E \s
    $re\Q [info] Found 4 dists\E
$}x, 'part 0 of output matches';

like $out[1], qr{^
    $re\Q [info] Processing dist 1 of 4\E \s
    $re\Q [info] Using ModulesPerl6::DbBuilder::Dist::Source::GitHub to load \E
        \Qhttps://raw.githubusercontent.com/zoffixznet/perl6-modules.perl6.\E
        \Qorg-test1/master/META.info\E \s
    $re\Q [info] Fetching distro info and commits\E \s
    $re\Q [info] Downloading META file from https://raw.githubusercontent.\E
        \Qcom/zoffixznet/perl6-modules.perl6.org-test1/master/META.info\E \s
    $re\Q [info] Parsing META file\E \s
    $re\Q [warn] Required `perl` field is missing\E \s
    $re\Q [info] Dist has new commits. Fetching more info.\E
$}x, , 'part 1 of output matches';

like $out[2], qr{^
    $re\Q [info] Processing dist 2 of 4\E \s
    $re\Q [info] Using ModulesPerl6::DbBuilder::Dist::Source::GitHub to \E
        \Qload https://raw.githubusercontent.com/zoffixznet/perl6-modules.\E
        \Qperl6.org-test2/master/META.no-dist-name\E \s
    $re\Q [info] Fetching distro info and commits\E \s
    $re\Q [info] Downloading META file from https://raw.githubusercontent.com\E
        \Q/zoffixznet/perl6-modules.perl6.org-test2/master/META.\E
        \Qno-dist-name\E\s
    $re\Q [info] Parsing META file\E \s
    $re\Q [warn] Required `perl` field is missing\E \s
    $re\Q [warn] Required `name` field is missing\E
$}x, , 'part 2 of output matches';

like $out[3], qr{^
    $re\Q [info] Processing dist 3 of 4\E \s
    $re\Q [info] Using ModulesPerl6::DbBuilder::Dist::Source::GitHub to \E
        \Qload https://raw.githubusercontent.com/zoffixznet/perl6-modules\E
        \Q.perl6.org-test3/master/META.info\E \s
    $re\Q [info] Fetching distro info and commits\E \s
    $re\Q [info] Downloading META file from https://raw.githubusercontent.\E
        \Qcom/zoffixznet/perl6-modules.perl6.org-test3/master/META.info\E \s
    $re\Q [info] Parsing META file\E \s
    $re\Q [warn] Required `perl` field is missing\E \s
    $re\Q [info] Dist has new commits. Fetching more info.\E \s
    $re\Q [info] Dist has a logotype of size 160 bytes.\E \s
    $re\Q [info] Did not find cached dist logotype. Downloading.\E
$}x, , 'part 3 of output matches';

like $out[4], qr{^
    $re\Q [info] Processing dist 4 of 4\E \s
    $re\Q [info] Using ModulesPerl6::DbBuilder::Dist::Source::GitHub to \E
        \Qload https://raw.githubusercontent.com/zoffixznet/perl6-Color/\E
        \Qmaster/META.info\E \s
    $re\Q [info] Fetching distro info and commits\E \s
    $re\Q [info] Downloading META file from https://raw.githubusercontent.com\E
        \Q/zoffixznet/perl6-Color/master/META.info\E \s
    $re\Q [info] Parsing META file\E \s
    $re\Q [warn] Required `perl` field is missing\E \s
    $re\Q [info] Dist has new commits. Fetching more info.\E \s
    $re\Q [info] Dist has a logotype of size 1390 bytes.\E \s
    $re\Q [info] Did not find cached dist logotype. Downloading.\E \s
    $re\Q [info] Determined travis status is \E ([a-z]+)
$}x, , 'part 4 of output matches';

like $out[5], qr{^
$}x, , 'part 5 of output matches';

like $out[6], qr{^
    $re\Q [info] Finished building all dists. Performing cleanup.\E \s
    $re\Q [info] Removed 2 dists that are no longer in the ecosystem\E \s
    $re\Q [info] Finished build \E ([\w=]{12,30})
$}x, , 'part 6 of output matches';

done_testing;


sub get_meta_list {
    return <<'END'
https://raw.githubusercontent.com/zoffixznet/perl6-modules.perl6.org-test1/master/META.info
https://raw.githubusercontent.com/zoffixznet/perl6-modules.perl6.org-test2/master/META.no-dist-name
https://raw.githubusercontent.com/zoffixznet/perl6-modules.perl6.org-test3/master/META.info
https://raw.githubusercontent.com/zoffixznet/perl6-Color/master/META.info
END
}