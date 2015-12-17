#!perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use constant METRIC => 'ModulesPerl6::Metrics::Koalatee';

use_ok       METRIC;
my $m     =  METRIC->new;
isa_ok $m => METRIC;
can_ok $m => qw/total  details/;

my @dists = (
    +{ # 0: no metrics passed

    },
    { # 1: max koalatee
        has_readme => 1,
        has_tests  => 1,
        panda  => 2,
        travis_status => 'passing',
    },
    { # 2: min koalatee
        has_readme => 0,
        has_tests  => 0,
        panda  => 0,
        travis_status => 'failing',
    },
    { # 3
        has_readme => 0,
        has_tests  => 1,
        panda  => 2,
        travis_status => 'passing',
    },
    { # 4
        has_readme => 0,
        has_tests  => 0,
        panda  => 2,
        travis_status => 'passing',
    },
    { # 5
        has_readme => 0,
        has_tests  => 0,
        panda  => 1,
        travis_status => 'whatever',
    },
    { # 6
        has_readme => 1,
        has_tests  => 0,
        panda  => 0,
        travis_status => 'failing',
    },
);

subtest 'calculate total Koalatee' => sub {
    my @expected = (20, 100, 0, 80, 60, 40, 20);
    for my $idx ( 0 .. $#dists ) {
        is $m->total( $dists[$idx] ), $expected[$idx],
            "Dist $idx has correct total koalatee";
    }
};

subtest 'calculate detailed Koalatee' => sub {
    my @readme = (
        name => 'has_readme',
        desc => 'Does a distribution have a README file?',
        max  => 1,
    );
    my @tests = (
        name => 'has_tests',
        desc => 'Does a distribution have tests?',
        max  => 1,
    );
    my @panda = (
        name => 'panda',
        desc => 'META file conformance level to spec',
        max  => 2,
    );
    my @travis = (
        name => 'travis_status',
        desc => 'This metric does not pass for distributions '
                    . 'with failing Travis-CI builds',
        max  => 1,
    );
    my @expected = (
        [
            { val => 0, @readme },
            { val => 0, @tests  },
            { val => 0, @panda  },
            { val => 1, @travis },
        ],
        [
            { val => 1, @readme },
            { val => 1, @tests  },
            { val => 2, @panda  },
            { val => 1, @travis },
        ],
        [
            { val => 0, @readme },
            { val => 0, @tests  },
            { val => 0, @panda  },
            { val => 0, @travis },
        ],
        [
            { val => 0, @readme },
            { val => 1, @tests  },
            { val => 2, @panda  },
            { val => 1, @travis },
        ],
        [
            { val => 0, @readme },
            { val => 0, @tests  },
            { val => 2, @panda  },
            { val => 1, @travis },
        ],
        [
            { val => 0, @readme },
            { val => 0, @tests  },
            { val => 1, @panda  },
            { val => 1, @travis },
        ],
        [
            { val => 1, @readme },
            { val => 0, @tests  },
            { val => 0, @panda  },
            { val => 0, @travis },
        ],
    );
    for my $idx ( 0 .. $#dists ) {
        is_deeply $m->details( $dists[$idx] ), $expected[$idx],
            "Dist $idx has correct detailed koalatee";
    }
};


done_testing;
