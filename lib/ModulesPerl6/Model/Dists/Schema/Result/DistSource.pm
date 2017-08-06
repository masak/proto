package ModulesPerl6::Model::Dists::Schema::Result::DistSource;
use     ModulesPerl6::Model::ResultClass;

primary_column source => { data_type => 'text' };

has_many dists
    => 'ModulesPerl6::Model::Dists::Schema::Result::Dist'
    => { 'foreign.dist_source' => 'self.source' };

1;

__END__
