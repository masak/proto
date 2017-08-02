package ModulesPerl6::Model::Dists::Schema::Result::AppveyorStatus;
use     ModulesPerl6::Model::ResultClass;

primary_column status => { data_type => 'text' };

has_many dists
    => 'ModulesPerl6::Model::Dists::Schema::Result::Dist'
    => { 'foreign.appveyor_status' => 'self.status' };

1;

__END__

=encoding utf8

=for stopwords dists

=head1 NAME

ModulesPerl6::Model::Dists::Schema::Result::AppveyorStatus - Appveyor statuses

=head1 DESCRIPTION

This table stores L<https://appveyor.com/> statuses for the dists.

=head1 CONTACT INFORMATION

Original version of this module was written by Zoffix Znet
(L<https://github.com/zoffixznet/>, C<Zoffix> on irc.freenode.net).

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
