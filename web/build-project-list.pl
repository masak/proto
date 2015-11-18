#!/usr/bin/perl
use strict;
use warnings;
use 5.010;

use lib qw{lib  lib-db-builder};
use File::Path qw(make_path  remove_tree);
use File::Spec::Functions qw(catdir);
use Getopt::Long qw(GetOptions);
use P6Project;

GetOptions(
    'limit=s'      => \my $limit,
    'no-app-start' => \my $no_app_start,
);

my $output_dir = shift(@ARGV) || './';
binmode STDOUT, ':encoding(UTF-8)';

local $| = 1;

my $min_popular = 10;

my $list_url = 'https://raw.githubusercontent.com/perl6/ecosystem/master/META.list';

my $template = './index.tmpl';

my $logos_dir = catdir $output_dir, qw/public content-pics dist-logos/;
remove_tree $logos_dir;
make_path $logos_dir, => { mode => 0755 };

my $p6p = P6Project->new(
    output_dir   => $output_dir,
    min_popular  => $min_popular,
    template     => $template,
    limit        => $limit,
    no_app_start => $no_app_start,
);

$p6p->load_projects($list_url);

my $success = $p6p->stats->success;
my $failed  = $p6p->stats->failed;
print "ok - $success\nnok - $failed\n";

my @errors = $p6p->stats->errors;
warn join "\n", @errors, '' if @errors;

die "Too many errors no output generated"
  if $failed > $success;

$p6p->write_json('proto.json');
$p6p->write_html('index.html'); # this doesn't actually write anything ATM
# $p6p->write_sprite;
$p6p->write_dist_db;

print "index.html and proto.json files generated\n";

