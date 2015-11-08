#!/usr/bin/perl
use strict;
use warnings;
use 5.010;

use lib 'lib';
use File::Path qw(make_path);
use Getopt::Long qw(GetOptions);
use P6Project;

GetOptions('limit=s' => \my $limit);

my $output_dir = shift(@ARGV) || './';
binmode STDOUT, ':encoding(UTF-8)';

local $| = 1;

my $min_popular = 10;

my $list_url = 'https://raw.githubusercontent.com/perl6/ecosystem/master/META.list';

my $template = './index.tmpl';

make_path("$output_dir/assets/images/logos", { mode => 0755 }) unless -e "$output_dir/assets/images/logos";

my $p6p = P6Project->new(output_dir=>$output_dir, min_popular=>$min_popular, template=>$template, limit=>$limit);

$p6p->load_projects($list_url);

my $success = $p6p->stats->success;
my $failed  = $p6p->stats->failed;
print "ok - $success\nnok - $failed\n";

my @errors = $p6p->stats->errors;
warn join "\n", @errors, '' if @errors;

die "Too many errors no output generated"
  if $failed > $success;

unless ($output_dir eq './') {
    system qw/cp fame-and-profit.html/, $output_dir;
    system qw/cp -r assets           /, $output_dir;
}

$p6p->write_json('proto.json');
$p6p->write_html('index.html');
$p6p->write_sprite;

print "index.html and proto.json files generated\n";

