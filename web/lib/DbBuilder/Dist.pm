package DbBuilder::Dist;

use strictures 2;

use Types::Standard qw/Str/;

use Moo;
use namespace::clean;

has _build_id => (
    init_arg => 'build_id',
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has _meta_url => (
    init_arg => 'meta_url',
    is       => 'ro',
    isa      => Str,
    required => 1,
);

1;