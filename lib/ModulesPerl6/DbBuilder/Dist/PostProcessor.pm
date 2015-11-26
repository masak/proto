package ModulesPerl6::DbBuilder::Dist::PostProcessor;

use strictures 2;

use Types::Standard qw/InstanceOf  Maybe  Ref  Str/;
use ModulesPerl6::DbBuilder::Log;

use Moo;
use namespace::clean;

has _dist => (
    init_arg => 'dist',
    is       => 'ro',
    isa      => Maybe[Ref['HASH'] | InstanceOf['JSON::Meth']],
    requireq => 1,
);

has _meta_url => (
    init_arg => 'meta_url',
    is       => 'ro',
    isa      => Str,
    required => 1,
);

sub process { ... }

1;