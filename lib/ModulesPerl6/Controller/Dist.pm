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
        ($from   ? (dist_source => $from) : ()),
        ($author ? (author_id   => $author) : ()),
        #         ($from   ? (distro_source => {source    => $from  }) : ()),
        # ($author ? (author        => {author_id => $author}) : ()),
    });
    use Acme::Dump::And::Dumper;
    print DnD [ $self->stash('dist'), $wanted, $from, $author, $dists->@* ];
    return $self->reply->not_found unless $dists->@*;
    return $self->redirect_to($dists->first->{url}) if $dists->@* == 1;

    $self->stash(wanted => $wanted, dists => $dists);
}

1;

__END__
