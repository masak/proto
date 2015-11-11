package ModulesPerl6::Model::BuildStats;

use Mojo::Base -base;

use Carp             qw/croak/;
use Mojo::Collection qw/c/;
use Mojo::Util       qw/trim/;
use Package::Alias Schema => 'ModulesPerl6::Model::BuildStats::Schema';

has db_file => $ENV{MODULESPERL6_DB_FILE} // 'modulesperl6.db';
has db      => sub { Schema->connect('dbi:SQLite:' . shift->db_file) };

sub deploy {
    my $self = shift;
    $self->db->deploy;

    $self;
}

sub update {
    my ( $self, %stats ) = @_;
    my @to_delete = grep ! defined $stats{$_}, keys %stats;
    if ( @to_delete ) {
        delete @stats{ @to_delete };
        $self->db->resultset('BuildStats')->search({
            stat => { -in => \@to_delete }
        })->delete;
    }

    keys %stats or return $self;

    $self->db->resultset('BuildStats')->update_or_create({
        stat  => $_,
        value => $stats{$_},
    }) for sort keys %stats;

    $self;
}

sub stats {
    my ( $self, @stats ) = @_;
    @stats or return {};

    my %res = map +( $_->{stat} => $_->{value} ),
        $self->db->resultset('BuildStats')->search(
            { stat => { -in => \@stats } },
            { result_class => 'DBIx::Class::ResultClass::HashRefInflator' },
        );

    return \%res;
}

1;