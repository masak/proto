package ModulesPerl6::Model::ResultClass;

use Import::Into;
sub import {
    strictures->import::into(1);
    DBIx::Class::Candy->import::into(1, -autotable => v1);
}

1;

__END__

=encoding utf8

=head1 NAME

ModulesPerl6::Model::ResultClass - import base for ::Result classes

=head1 SYNOPSIS

    package ModulesPerl6::Model::Foo::Schema::Result::Bars;
    use     ModulesPerl6::Model::ResultClass;

    primary_column some_id => { data_type => 'text' };

    1;

=head1 DESCRIPTION

Simply C<use> this module in your L<DBIx::Class>
L<Result classes|https://metacpan.org/pod/DBIx::Class::ResultSource>
to import L<strictures> and L<DBIx::Class::Candy>. i.e. it's the same
as doing this in your class, except should that boilerplate change, you'd
only have to change it in class and not each Result class:

    use strictures;
    use DBIx::Class::Candy;

=head1 CONTACT INFORMATION

Original version of this module was written by Zoffix Znet
(L<https://github.com/zoffixznet/>, C<Zoffix> on irc.freenode.net).

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
