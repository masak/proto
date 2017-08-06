package ModulesPerl6::Model::Dists::Schema::Result::Dist;
use     ModulesPerl6::Model::ResultClass;

primary_column meta_url      => { data_type => 'text',                     };
column         name          => { data_type => 'text'                      };
column         author_id     => { data_type => 'text', is_foreign_key => 1 };
column         build_id      => { data_type => 'text', is_foreign_key => 1 };
column         dist_source   => { data_type => 'text', is_foreign_key => 1 };
column         travis_status => { data_type => 'text', is_foreign_key => 1 };
column         appveyor_status => { data_type => 'text', is_foreign_key => 1 };
column         appveyor_url  => { data_type => 'text',                     };
column         url           => { data_type => 'text'                      };
column         description   => { data_type => 'text'                      };
column         stars         => { data_type => 'integer'                   };
column         issues        => { data_type => 'integer'                   };
column         date_updated  => { data_type => 'integer'                   };
column         date_added    => { data_type => 'integer'                   };

has_many tag_dists
    => 'ModulesPerl6::Model::Dists::Schema::Result::TagDist'
    => 'dist';

many_to_many tags => tag_dists => 'tag';

has_many problem_dists
    => 'ModulesPerl6::Model::Dists::Schema::Result::ProblemDist'
    => 'dist';

many_to_many problems => problem_dists => 'problem';

belongs_to author
    => 'ModulesPerl6::Model::Dists::Schema::Result::Author'
    => 'author_id';

belongs_to distro_source
    => 'ModulesPerl6::Model::Dists::Schema::Result::DistSource'
    => { source => 'dist_source' };

belongs_to travis
    => 'ModulesPerl6::Model::Dists::Schema::Result::TravisStatus'
    => { status => 'travis_status' };

belongs_to appveyor
    => 'ModulesPerl6::Model::Dists::Schema::Result::AppveyorStatus'
    => { status => 'appveyor_status' };

belongs_to dist_build_id
    => 'ModulesPerl6::Model::Dists::Schema::Result::BuildId'
    => { id => 'build_id' };

1;

__END__

=encoding utf8

=for stopwords distro

=head1 NAME

ModulesPerl6::Model::Dists::Schema::Result::Dist - Distribution info table

=head1 DESCRIPTION

This table stores distro information.

=head1 CONTACT INFORMATION

Original version of this module was written by Zoffix Znet
(L<https://github.com/zoffixznet/>, C<Zoffix> on irc.freenode.net).

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
