package ModulesPerl6::Model::Dists::Schema::Result::Dist;
use     ModulesPerl6::Model::ResultClass;

primary_column name          => { data_type => 'text'                      };
primary_column author_id     => { data_type => 'text', is_foreign_key => 1 };
column         travis_status => { data_type => 'text', is_foreign_key => 1 };
column         url           => { data_type => 'text'                      };
column         description   => { data_type => 'text'                      };
column         logo          => { data_type => 'text'                      };
column         kwalitee      => { data_type => 'integer'                   };
column         stars         => { data_type => 'integer'                   };
column         issues        => { data_type => 'integer'                   };
column         date_updated  => { data_type => 'integer'                   };
column         date_added    => { data_type => 'integer'                   };

belongs_to author
    => 'ModulesPerl6::Model::Dists::Schema::Result::Author'
    => 'author_id';

belongs_to travis
    => 'ModulesPerl6::Model::Dists::Schema::Result::TravisStatus'
    => { status => 'travis_status' };

1;
