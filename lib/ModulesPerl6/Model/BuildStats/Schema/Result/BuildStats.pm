package ModulesPerl6::Model::BuildStats::Schema::Result::BuildStats;
use     ModulesPerl6::Model::ResultClass;

primary_column stat  => { data_type => 'text' };
column         value => { data_type => 'text' };

1;

__END__

=encoding utf8

=head1 NAME

ModulesPerl6::Model::BuildStats::Schema::Result::BuildStats - table storing various statistics on the database builds

=head2 DESCRIPTION

This table is populated when the build script is run, storing info like
date of last build of the database and the number of dists in the ecosystem.

=head1 CONTACT INFORMATION

Original version of this module was written by Zoffix Znet
(L<https://github.com/zoffixznet/>, C<Zoffix> on irc.freenode.net).

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
