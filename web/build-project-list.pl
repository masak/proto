#!/usr/bin/perl

use strictures 2;

use File::Spec::Functions qw/catdir  catfile/;
use Getopt::Long;

use lib qw/lib/;
use DbBuilder;

use constant DB_FILE        => 'modulesperl6.db';
use constant APP            => catfile qw/bin  ModulesPerl6.pl/;
use constant META_LIST_FILE => 'https://raw.githubusercontent.com'
                                    . '/perl6/ecosystem/master/META.list';

my $meta_list = META_LIST_FILE;
GetOptions(
    'meta-list=s' => \$meta_list,
    'limit=i'     => \my $limit,
    'restart-app' => \my $restart_app,
);

DbBuilder->new(
    app         => APP,
    db_file     => DB_FILE,
    limit       => $limit,
    logos_dir   => catdir(qw/public  content-pics  dist-logos/),
    meta_list   => $meta_list,
    restart_app => $restart_app,
)->run;
