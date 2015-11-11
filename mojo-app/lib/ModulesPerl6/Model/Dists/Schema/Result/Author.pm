package ModulesPerl6::Model::Dists::Schema::Result::Author;
use     ModulesPerl6::Model::ResultClass;

primary_column author_id => { data_type => 'text' };
column         name      => { data_type => 'text' };

has_many dists
    => 'ModulesPerl6::Model::Dists::Schema::Result::Dist' => 'author_id';

1;
