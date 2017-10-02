package ModulesPerl6::Controller::Dist;

use Mojo::Base 'Mojolicious::Controller';
use experimental 'postderef';

sub dist {
    my $self = shift;
                                  # Foo::Bar:from:author
    my ($wanted, $from, $author) = split /(?<!:):(?!:)/,
        $self->stash('dist'), 3;

    my $dists = $self->dists->find({
        name => $wanted,
        ($from   ? (dist_source => $from  ) : ()),
        ($author ? (author_id   => $author) : ()),
    });

    return $self->reply->not_found unless $dists->@*;
    return $self->stash(
        wanted => $wanted, dists => $dists, template => 'dist/ambiguous-dist',
    ) if $dists->@* > 1;
    return $self->redirect_to($dists->first->{url})
        if $dists->@* == 1 and $dists->first->{dist_source} ne 'cpan';

    $self->stash(dist => $dists->first);
}

1;

__END__
