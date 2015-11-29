package ModulesPerl6::Model::Dists::Schema::Result::Dist;
use     ModulesPerl6::Model::ResultClass;

primary_column name          => { data_type => 'text'                      };
primary_column meta_url      => { data_type => 'text',                     };
column         author_id     => { data_type => 'text', is_foreign_key => 1 };
column         build_id      => { data_type => 'text', is_foreign_key => 1 };
column         travis_status => { data_type => 'text', is_foreign_key => 1 };
column         url           => { data_type => 'text'                      };
column         description   => { data_type => 'text'                      };
column         koalatee      => { data_type => 'integer'                   };
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
