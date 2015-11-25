#!perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use Test::Output qw/combined_from/;

BEGIN { use_ok 'ModulesPerl6::DbBuilder::Log' };

my ( $out, $ret );
my $time_stamp_re = qr/\[\w{3} \w{3} \d\d? \d{2}:\d{2}:\d{2} \d{4}\]/;

for ( qw/debug info warn error/ ) {
    $out = combined_from sub { $ret = log $_ => "This is $_ log"; };
    like $out => qr/^$time_stamp_re \[$_\] This is $_ log$/, "$_ log works";
    is $ret, "This is $_ log", 'return value of log() is the message';
}

subtest 'fatal level log' => sub {
    $out = combined_from sub { eval { log fatal => 'This is fatal log' } };
    like $out => qr/^$time_stamp_re \[fatal\] This is fatal log$/,
            'fatal log has correct message';

    throws_ok { combined_from sub {log fatal  => 'dies';} }
        qr/^\*died through fatal level log message\*$/, 'fatal log dies';
};

dies_ok { log foobar => 'dies'; } 'dies on non-existent log level';
throws_ok { eval "log info => 'foo', 'bar'"; $@ and die; }
    qr/Too many arguments/, 'prototype catches screw ups';

done_testing;