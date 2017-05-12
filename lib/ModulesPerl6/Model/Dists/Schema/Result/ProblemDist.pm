package ModulesPerl6::Model::Dists::Schema::Result::ProblemDist;
use     ModulesPerl6::Model::ResultClass;

primary_column problem => { data_type => 'text', is_foreign_key => 1  };
primary_column dist => { data_type => 'text', is_foreign_key => 1  };

belongs_to problem => 'ModulesPerl6::Model::Dists::Schema::Result::Problem';
belongs_to dist => 'ModulesPerl6::Model::Dists::Schema::Result::Dist';

1;

__END__
