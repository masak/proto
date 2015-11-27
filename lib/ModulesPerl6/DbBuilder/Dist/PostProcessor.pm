package ModulesPerl6::DbBuilder::Dist::PostProcessor;

use ModulesPerl6::DbBuilder::Log;
use Mew;

has _dist     => Maybe[Ref['HASH'] | InstanceOf['JSON::Meth']];
has _meta_url => Str;

sub process { ... }

1;