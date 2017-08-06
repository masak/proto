package ModulesPerl6::Controller::Root;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::URL;
use POSIX qw/strftime/;
use experimental 'postderef';

sub index {
    my $self = shift;
    $self->stash(body_class => 'page_index');
}

sub search {
    my $self = shift;
    my $q = $self->param('q') // return $self->redirect_to('home');

    my @dists = $self->dists->find({ name        => \$q })->each,
                $self->dists->find({ description => \$q })->each;

    for (@dists) {
        $_->{source} = 'github'; # TODO XXX: use dist source data from db
        $_->{date_updated} = $_->{date_updated}
            ? strftime '%Y-%m-%d', gmtime $_->{date_updated}
            : 'N/A';

        $_->{travis_url} = Mojo::URL->new($_->{url})->host('travis-ci.org');

        my $m = Mojo::URL->new($_->{url});
        $_->{appveyor_url} = $m->host('ci.appveyor.com')
            ->path('/project' . $m->path);
    }

    $self->stash(dists => \@dists);
}

sub total {
    my $self = shift;

    $self->render(
        text => $self->build_stats->stats('dists_num')->{dists_num}
    );
}

sub repo {
    my $self = shift;

    my $dist = $self->stash('dist');
    return $self->reply->not_found
        unless $dist = $self->dists->find({name => $dist})->first;

    return $self->redirect_to( $dist->{url} );
}

1;

__END__
