package ModulesPerl6::Model::Dists::Schema::Result::Tag;
use     ModulesPerl6::Model::ResultClass;

primary_column tag_id => { data_type => 'integer', auto_increment => 1};
        column tag    => { data_type => 'text' };

has_many tag_dists
    => 'ModulesPerl6::Model::Dists::Schema::Result::TagDist',
    => 'tag';

many_to_many dists => tag_dists => 'dist';

1;

__END__
