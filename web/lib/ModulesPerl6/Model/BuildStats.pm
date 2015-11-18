package ModulesPerl6::Model::BuildStats;

use Mojo::Base -base;

use Carp             qw/croak/;
use File::Spec::Functions qw/catfile/;
use FindBin;
use Mojo::Collection qw/c/;
use Mojo::Util       qw/trim/;
use ModulesPerl6::Model::BuildStats::Schema;

has db_file => sub {
    $ENV{MODULESPERL6_DB_FILE}// catfile $FindBin::Bin, qw/.. modulesperl6.db/;
};

has _db     => sub {
    ModulesPerl6::Model::BuildStats::Schema
        ->connect('dbi:SQLite:' . shift->db_file)
};

sub deploy {
    my $self = shift;
    $self->_db->deploy;

    $self;
}

sub update {
    my ( $self, %stats ) = @_;
    my @to_delete = grep ! defined $stats{$_}, keys %stats;
    if ( @to_delete ) {
        delete @stats{ @to_delete };
        $self->_db->resultset('BuildStats')->search({
            stat => { -in => \@to_delete }
        })->delete;
    }

    keys %stats or return $self;

    $self->_db->resultset('BuildStats')->update_or_create({
        stat  => $_,
        value => $stats{$_},
    }) for sort keys %stats;

    $self;
}

sub stats {
    my ( $self, @stats ) = @_;
    @stats or return {};

    my %res = map +( $_->{stat} => $_->{value} ),
        $self->_db->resultset('BuildStats')->search(
            { stat => { -in => \@stats } },
            { result_class => 'DBIx::Class::ResultClass::HashRefInflator' },
        );

    return \%res;
}

1;

__END__

=encoding utf8

=head1 NAME

ModulesPerl6::Model::BuildStats - model representing database build statistics

=head1 SYNOPSIS

    my $m = ModulesPerl6::Model::BuildStats->new( db_file => 'mydb.db' );

    $m->deploy;
    $m->update(
        dists_num    => scalar(keys %{ $self->projects }),
        last_updated => time(),
    );
    $m->update( last_updated => undef ); # remove `last_updated` stat

    say $m->stats(qw/foo bar baz/)->{foo};

=head1 DESCRIPTION

This module is used to access and manipulate the build statistics gathered
during the database build process by the build script.

=head2 C<db_file>

    say "Using database file: " . $m->db_file

Contains database filename (see L</new>).

=head1 METHODS

=head2 C<new>

    my $m = ModulesPerl6::Model::BuildStats->new;

    my $m = ModulesPerl6::Model::BuildStats->new( db_file => 'mydb.db' );

Creates and returns a new C<ModulesPerl6::Model::BuildStats> object. Takes
these arguments:

=head3 C<db_file>

    my $m = ModulesPerl6::Model::BuildStats->new( db_file => 'mydb.db' );

B<Optional>. Specifies the filename of the SQLite database with dist info.
B<Defaults to:> the value of C<MODULESPERL6_DB_FILE> environmental variable,
if set, or C<modulesperl6.db>.

=head2 C<deploy>

    $m->deploy

B<Takes> no arguments. B<Returns> its invocant. Deploys (creates) the SQL
tables needed for this module to operate. B<Will die> if they already exists.

=head2 C<update>

    $m->update(
        dists_num    => scalar(keys %{ $self->projects }),
        last_updated => time(),
    );
    $m->update( last_updated => undef ); # remove `last_updated` stat

Updates or deletes stats.
B<Takes> key/value pairs of stat names and their values. If a value is
C<undef>, that stat is deleted from the database. B<Returns> its invocant.

=head2 C<stats>

    say $m->stats(qw/foo bar baz/)->{foo};

B<Takes> a list of stats to retrieve. B<Returns> a hashref where keys are
the names of stats and values are the values of the stats.

=head1 PRIVATE ATTRIBUTES

B<These attributes are documented for developers working on this module.
Do NOT use these attributes outside of this package.>

=head2 C<_db>

Contains C<ModulesPerl6::Model::BuildStats::Schema> L<DBIx::Class::Schema>
object.

=head1 CONTACT INFORMATION

Original version of this module was written by Zoffix Znet
(L<https://github.com/zoffixznet/>, C<Zoffix> on irc.freenode.net).

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
