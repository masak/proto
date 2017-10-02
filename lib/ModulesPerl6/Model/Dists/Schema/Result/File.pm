package ModulesPerl6::Model::Dists::Schema::Result::File;
use     ModulesPerl6::Model::ResultClass;

primary_column file   => { data_type => 'text'                       };
primary_column dist   => { data_type => 'text', is_foreign_key => 1  };

belongs_to dist => 'ModulesPerl6::Model::Dists::Schema::Result::Dist';

1;
__END__
