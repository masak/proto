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

    my %tags;
    for ( @$dists ) {
        $tags{$_}++ for @{ $_->{tags} };
        my $logo_base = 's-' . $_->{name} =~ s/\W/_/gr;
        $_->{logo} = $logo_base if $self->app->static->file(
            "content-pics/dist-logos/$logo_base.png"
        );

        $_->{date_updated} = $_->{date_updated} ? strftime "%Y-%m-%d",
                           gmtime $_->{date_updated} : 'N/A';

        $_->{travis_url}   = Mojo::URL->new($_->{url})->host('travis-ci.org');
        $_->{is_hidden}    = 1
            if length $q and not $found_dists{"$_->{name}\0$_->{author_id}"};
    }

    my $active_tag = uc($self->param('tag') // '');
    @$dists = grep { grep $_ eq $active_tag, @{ $_->{tags} } } @$dists
        if $active_tag;

    my @tags = map +{
        tag        => $_,
        count      => $tags{$_},
        is_weak    => $tags{$_} < 3,
    }, sort keys %tags;

    my %data = (
        is_active_weak_tag => (
            scalar grep { $_->{is_weak} and $_->{tag} eq $active_tag } @tags
        ),
        tags  => [
            ( grep { $_->{count} >= 3 } @tags ),
            ( grep { $_->{count}  < 3 } @tags )
        ],
        dists => $dists,
        more  => $self->url_for('current')->to_abs,
        $self->build_stats->stats(qw/dists_num  last_updated/)->%*,
    );

    $self->respond_to(
        html => { %data, template => 'root/index' },
        json => { json => {
            dists => [ grep !$_->{is_hidden}, @{$data{dists}} ],
        }},
    );
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

sub not_implemented_yet {
    shift->render( text => 'Not Implemented Yet' );
}

1;

__END__

=encoding utf8

=for stopwords NIY dists

=head1 NAME

ModulesPerl6::Controller::Root - controller handling a few root-space pages

=head1 SYNOPSIS

    my $r = $self->routes;
    $r->get( $_ )->to('root#index') for qw{/  /q/:q  /s/:q  /search/:q};
    $r->get('/dist/:dist')->to('root#dist')->name('dist');
    $r->get('/total')->to('root#total')->name('total');

    $r->any('/not_implemented_yet')
        ->to('root#not_implemented_yet')
        ->name('not_implemented_yet');

=head1 DESCRIPTION

This controller should be used for "root-space" pages, such as the home page,
about page (if any), and stuff that is too demand its own controller.

It is recommended that any feature with a set of pages specifically related to
it gets its own controller.

=head1 ACTIONS

=head2 C<index>

    $r->get( $_ )->to('root#index') for qw{/  /q/:q  /s/:q  /search/:q};

Render the home page, optionally providing search results. This action
is aliased under several routes (see example above), and handles C<q> query
parameter that is the term to perform the search for.

=head2 C<dist>

    $r->get('/dist/:dist')->to('root#repo')->name('dist');

Render dist page (B<NIY>; currently just a redirect to GitHub repo).
Expects the name of the dist in C<dist>
L<Mojolicious::Controller/"stash"> parameter.

=head2 C<not_implemented_yet>

    $r->any('/not_implemented_yet')
        ->to('root#not_implemented_yet')
        ->name('not_implemented_yet');

A page that displays text 'Not Implemented Yet'. Actions that are not
yet implemented can redirect to this action to inform the user.

=head2 C<repo>

    $r->get('/repo/:dist')->to('root#repo')->name('repo');

Redirect to dist's GitHub repo. Expects the name of the dist in C<dist>
L<Mojolicious::Controller/"stash"> parameter.

=head2 C<total>

    $r->get('/total')->to('root#total')->name('total');

Responds with a plain text that displays total number of dists in the
database. This route was added to make it easier to encourage stats sites
like L<http://www.modulecounts.com> to add Perl 6 ecosystem (they can just
fetch the totals instead of Parsing HTML).

B<NOTE:> currently this route is known to be used by
L<http://www.modulecounts.com>, so it's important to keep it in working order.

=head1 CONTACT INFORMATION

Original version of this module was written by Zoffix Znet
(L<https://github.com/zoffixznet/>, C<Zoffix> on irc.freenode.net).

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
