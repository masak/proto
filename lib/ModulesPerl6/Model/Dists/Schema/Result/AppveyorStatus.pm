package ModulesPerl6::Model::Dists::Schema::Result::AppveyorStatus;
use     ModulesPerl6::Model::ResultClass;

primary_column status => { data_type => 'text' };

has_many dists
    => 'ModulesPerl6::Model::Dists::Schema::Result::Dist'
    => { 'foreign.appveyor_status' => 'self.status' };

1;

__END__
