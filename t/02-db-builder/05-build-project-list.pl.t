#!perl

use strict;
use warnings FATAL => 'all';

use File::Temp qw/tempdir/;
use Mojo::Util qw/spurt/;
use Test::Most;
use Test::Script;
use t::Helper;

use ModulesPerl6::Model::Dists;
BEGIN { use_ok 'ModulesPerl6::DbBuilder::Dist' };

my $db_file = t::Helper::setup_db_file;
END { unlink $db_file };

my $logos_dir = tempdir CLEANUP => 1;
my $time_stamp_re = t::Helper::time_stamp_re;
my $meta_list = File::Temp->new;

spurt get_meta_list() => $meta_list;

my $out;
script_runs [
    'bin/build-project-list.pl',
    '--interval=0',
    "--meta-list=$meta_list",
], { stderr => \$out };

use Acme::Dump::And::Dumper;
warn DnD [ $out ];

done_testing;


sub get_meta_list {
    return <<'END'
https://raw.githubusercontent.com/zoffixznet/perl6-modules.perl6.org-test1/master/META.info
https://raw.githubusercontent.com/zoffixznet/perl6-modules.perl6.org-test2/master/META.no-dist-name
https://raw.githubusercontent.com/zoffixznet/perl6-modules.perl6.org-test3/master/META.info
https://raw.githubusercontent.com/zoffixznet/perl6-Color/master/META.info
END
}