#!/usr/bin/perl
use strict;
use warnings;
use 5.010;

use File::Path qw(make_path);

BEGIN { unshift @INC, './lib'; }

use P6Project;

my $output_dir = shift(@ARGV) || './';
my @MEDALS = qw<fresh readme tests unachieved camelia panda panda_nos11>;
binmode STDOUT, ':encoding(UTF-8)';

local $| = 1;

my $min_popular = 10;

my $list_url = 'https://raw2.github.com/perl6/ecosystem/master/META.list';

my $template = './index.tmpl';

make_path("$output_dir/logos", { mode => 0755 }) unless -e "$output_dir/logos";

my $p6p = P6Project->new(output_dir=>$output_dir, min_popular=>$min_popular, template=>$template);

$p6p->load_projects($list_url);

my $success = $p6p->stats->success;
my $failed  = $p6p->stats->failed;
print "ok - $success\nnok - $failed\n";

my @errors = $p6p->stats->errors;
print STDERR join '', map {"$_\n"} @errors if scalar(@errors);

die "Too many errors no output generated"
  if $failed > $success;

unless ($output_dir eq './') {
    system("cp $_.png $output_dir") for @MEDALS;
    system("cp fame-and-profit.html $output_dir");
    system("cp -r js $output_dir");
}

$p6p->write_json('proto.json');
$p6p->write_html('index.html');

print "index.html and proto.json files generated\n";

