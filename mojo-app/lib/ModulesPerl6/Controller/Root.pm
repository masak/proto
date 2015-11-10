package ModulesPerl6::Controller::Root;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::URL;
use POSIX qw/strftime/;

sub index {
    my $self = shift;

    my $dists = $self->dists->find;
    for ( @$dists ) {
        $_->{date_updated} = strftime "%Y-%m-%d", localtime $_->{date_updated};
        $_->{travis_url}   = Mojo::URL->new($_->{url})->host('travis-ci.org');
    }
    $self->stash( dists => $dists );
}

sub dist {
    my $self = shift;

    my $dist = $self->stash('dist');
    return $self->reply->not_found
        unless length $dist
            and $dist = $self->dists->find({name => $dist})->first;

    return $self->redirect_to( $dist->{url} );
}

sub kwalitee {
    shift->redirect_to('NIY');
}

sub NIY {
    shift->render( text => 'Not Implemented Yet' );
}
1;
