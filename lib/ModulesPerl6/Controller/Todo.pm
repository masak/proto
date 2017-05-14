package ModulesPerl6::Controller::Todo;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::URL;
use POSIX qw/strftime/;
use experimental 'postderef';

sub index {
    my $self = shift;

    my $dists = $self->dists->find;

    $self->respond_to(
        html => { dists => $dists, template => 'todo/index' },
        json => { json => { dists => $dists } },
    );
}

sub author {
    my $self = shift;
    my $author = $self->stash('author');
    my $dists = $self->dists->find({ author_id => { -like => "%$author%" } });

    $self->respond_to(
        html => { dists => $dists, template => 'todo/index' },
        json => { json => { dists => $dists } },
    );
}

1;

__END__

=encoding utf8

=for stopwords NIY dists

=head1 NAME

ModulesPerl6::Controller::Todo- controller handling the todo lists for modules
