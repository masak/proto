package ModulesPerl6::Model::Dists::Schema::Result::TravisStatus;
use     ModulesPerl6::Model::Dists::Schema::ResultClass;

primary_column status => { data_type => 'text' };

has_many dists
    => 'ModulesPerl6::Model::Dists::Schema::Result::Dist'
    => { 'foreign.travis_status' => 'self.status' };


1;
