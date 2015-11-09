package ModulesPerl6::Model::Dists;

use Mojo::Base -base;

use Carp             qw/croak/;
use Mojo::Collection qw/c/;
use Mojo::Util       qw/trim/;
use Package::Alias Schema   => 'ModulesPerl6::Model::Dists::Schema';
use Package::Alias Kwalitee => 'ModulesPerl6::Metrics::Kwalitee';

has db_file => $ENV{MODULESPERL6_DB_FILE} // 'modulesperl6.db';
has db      => sub { Schema->connect('dbi:SQLite:' . shift->db_file) };

sub _find {
    my $self   = shift;
    my $is_hri = shift;
    my $what   = shift // {};
    ref $what eq 'HASH' or croak 'find only accepts a hashref';

    %$what = map {
        ref $what->{$_} eq 'SCALAR'
            ? ( $_ => { -like => "%${ $what->{$_} }%" } )
            : $what->{$_}
                ? ( $_ => $what->{$_} ) : ()
    } qw/name  author_id  travis_status  description/;

    my $res = $self->db->resultset('Dist')->search($what,
        $is_hri ? {
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        } : ()
    );

    return $is_hri ? c $res->all : $res;
}

sub add {
    my ( $self, @data ) = @_;
    @data or return $self;

    my $db = $self->db;
    for my $dist ( @data ) {
        $_ = trim $_//'' for values %$dist;
        $dist->{travis_status} ||= 'not setup';
        $dist->{date_updated}  ||= 0;
        $dist->{date_added}    ||= 0;
        $dist->{kwalitee} = Kwalitee->new->kwalitee({
            map +( $_ => $dist->{$_} ),
                qw/has_readme  panda  has_tests  travis/,
        });

        $db->resultset('Dist')->create({
            travis => { status => $dist->{travis_status} },
            author => { # use same field for both, for now. TODO:fetch realname
                author_id => $dist->{author_id}, name => $dist->{author_id},
            },
            map +( $_ => $dist->{$_} ),
                qw/name  url  description  logo  stars  issues  kwalitee
                    date_updated  date_added/,
        });
    }

    $self;
}

sub deploy {
    my $self = shift;
    $self->db->deploy;

    $self;
}

sub find {
    my $self = shift;
    return $self->_find(1, @_);
}
sub remove {
    my $self = shift;
    $self->_find(0, @_)->delete_all;

    $self;
}

1;