package ModulesPerl6::Model::BuildStats::Schema::Result::BuildStats;
use     ModulesPerl6::Model::ResultClass;

primary_column stat   => { data_type => 'text' };
column         value  => { data_type => 'text' };

1;
