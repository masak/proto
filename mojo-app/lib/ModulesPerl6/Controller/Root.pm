package ModulesPerl6::Controller::Root;

use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $self = shift;

    $self->stash( dists => $self->dists->find );
}
1;
