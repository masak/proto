package ModulesPerl6::Model::Dists::Schema;

use strictures 2;
use base qw/DBIx::Class::Schema/;
__PACKAGE__->load_namespaces;

1;

__END__

need SQL::Translator >= 0.11018