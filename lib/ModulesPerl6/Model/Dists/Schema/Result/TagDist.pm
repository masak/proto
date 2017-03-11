package ModulesPerl6::Model::Dists::Schema::Result::TagDist;
use     ModulesPerl6::Model::ResultClass;

primary_column tag  => { data_type => 'text', is_foreign_key => 1  };
primary_column dist => { data_type => 'text', is_foreign_key => 1  };

belongs_to tag  => 'ModulesPerl6::Model::Dists::Schema::Result::Tag';
belongs_to dist => 'ModulesPerl6::Model::Dists::Schema::Result::Dist';

1;

__END__
