package ModulesPerl6::Model::Dists;

use Mojo::Base -base;

use Carp          qw/croak/;
use Mojo::SQLite;
use Mojo::Util    qw/trim/;

has db_file => $ENV{ALLAROUND_DB} // 'modulesperl6.db';
has _sqlite => \&_set_up_sqlite;

sub add {
    my ( $self, @data ) = @_;
    @data or return $self;

    my $db = $self->_sqlite->db;
    my $tx = $db->begin;
    for my $dist ( @data ) {
        $_ = trim $_//'' for values %$dist;
        $dist->{travis}       ||= 'not setup';
        $dist->{date_updated} ||= 0;
        $dist->{date_added}   ||= 0;

        $db->query(
            'INSERT OR IGNORE INTO authors (name, github) VALUES (?, ?)',
            @$dist{qw/author author/}, # eventually we'll have name/github...
            # ...but we'll use same field for both for now
        );

        $db->query(
            'INSERT OR IGNORE INTO travis_statuses (status) VALUES (?)',
            $dist->{travis},
        );

        $db->query(
            'INSERT INTO dists (
                name,         url,         description,
                logo,         stars,       issues,
                date_updated, date_added,  travis_status_id,
                author_id
            ) VALUES(?, ?, ?,  ?, ?, ?,  ?, ?,
                (SELECT travis_status_id
                    FROM travis_statuses WHERE status = ? ),
                (SELECT author_id FROM authors WHERE name = ? AND github = ?)
            )',
            @$dist{qw/
                name         url         description
                logo         stars       issues
                date_updated date_added  travis
                author       author
            /},
        );
    }
    $tx->commit;

    $self;
}

sub _set_up_sqlite {
    my $sqlite = Mojo::SQLite->new('file:' . shift->db_file);

    $sqlite->db->query(q{
        CREATE TABLE IF NOT EXISTS authors (
            author_id    INTEGER PRIMARY KEY AUTOINCREMENT,
            name         TEXT NOT NULL,
            github       TEXT NOT NULL,
            UNIQUE(name, github)
        );
    });

    $sqlite->db->query(q{
        CREATE TABLE IF NOT EXISTS travis_statuses (
            travis_status_id INTEGER PRIMARY KEY AUTOINCREMENT,
            status           TEXT UNIQUE NOT NULL
        );
    });

    $sqlite->db->query(q{
        CREATE TABLE IF NOT EXISTS dists (
            dist_id      INTEGER PRIMARY KEY AUTOINCREMENT,
            name         TEXT NOT NULL,
            url          TEXT NOT NULL,
            description  TEXT NOT NULL,
            logo         TEXT NOT NULL,
            stars        INTEGER NOT NULL,
            issues       INTEGER NOT NULL,
            date_updated INTEGER NOT NULL,
            date_added   INTEGER NOT NULL,
            FOREIGN KEY(travis_status_id)
                REFERENCES travis_statuses(travis_status_id),
            FOREIGN KEY(author_id)
                REFERENCES authors(author_id)
        );
    });

    return $sqlite;
};

1;