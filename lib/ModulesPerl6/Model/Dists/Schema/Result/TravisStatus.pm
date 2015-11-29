package ModulesPerl6::Model::Dists::Schema::Result::TravisStatus;
use     ModulesPerl6::Model::ResultClass;

primary_column status => { data_type => 'text' };

has_many dists
    => 'ModulesPerl6::Model::Dists::Schema::Result::Dist'
    => { 'foreign.travis_status' => 'self.status' };

1;

__END__

=encoding utf8

=for stopwords dists

=head1 NAME

ModulesPerl6::Model::Dists::Schema::Result::TravisStatus - Travis-CI statuses

=head1 DESCRIPTION

This table stores L<https://travis-ci.org/> statuses for the dists.

=head1 CONTACT INFORMATION

Original version of this module was written by Zoffix Znet
(L<https://github.com/zoffixznet/>, C<Zoffix> on irc.freenode.net).

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
