package ModulesPerl6::Model::Dists::Schema::Result::Author;
use     ModulesPerl6::Model::ResultClass;

primary_column author_id => { data_type => 'text' };
column         name      => { data_type => 'text' };

has_many dists
    => 'ModulesPerl6::Model::Dists::Schema::Result::Dist' => 'author_id';

1;

__END__

=encoding utf8

=head1 NAME

ModulesPerl6::Model::Dists::Schema::Result::Author - Author info table

=head1 DESCRIPTION

This table stores distribution authors info.

=head1 CONTACT INFORMATION

Original version of this module was written by Zoffix Znet
(L<https://github.com/zoffixznet/>, C<Zoffix> on irc.freenode.net).

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
