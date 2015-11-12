package ModulesPerl6::Controller::Root;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::URL;
use POSIX qw/strftime/;
use experimental 'postderef';

sub index {
    my $self = shift;

    my $dists = $self->dists->find;
    my %found_dists;
    my $q = $self->param('q');
    if ( length $q ) {
        # TODO: fix the model so we don't need to make 2 calls to ->find
        %found_dists = map +( "$_->{name}\0$_->{author_id}" => 1 ),
            $self->dists->find({ name        => \$q })->each,
            $self->dists->find({ description => \$q })->each;
    }

    for ( @$dists ) {
        $_->{date_updated} = strftime "%Y-%m-%d", localtime $_->{date_updated};
        $_->{travis_url}   = Mojo::URL->new($_->{url})->host('travis-ci.org');
        $_->{is_hidden}    = 1
            if length $q and not $found_dists{"$_->{name}\0$_->{author_id}"};
    }

    $self->stash(
        dists => $dists,
        $self->build_stats->stats(qw/dists_num  last_updated/)->%*,
    );
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
    shift->redirect_to('not_implemented_yet');
}

sub not_implemented_yet {
    shift->render( text => 'Not Implemented Yet' );
}
1;
