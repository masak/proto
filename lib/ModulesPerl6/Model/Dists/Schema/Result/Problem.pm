package ModulesPerl6::Model::Dists::Schema::Result::Problem;
use     ModulesPerl6::Model::ResultClass;

primary_column problem_id => { data_type => 'integer', auto_increment => 1};
        column problem    => { data_type => 'text' };
        column severity   => { data_type => 'integer' };

has_many problem_dists
    => 'ModulesPerl6::Model::Dists::Schema::Result::ProblemDist',
    => 'problem';

many_to_many dists => problem_dists => 'dist';

1;

__END__
