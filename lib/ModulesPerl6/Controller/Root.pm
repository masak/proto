package ModulesPerl6::Controller::Root;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::URL;
use List::UtilsBy qw/nsort_by  uniq_by/;
use POSIX qw/strftime/;
use experimental 'postderef';

sub index {
    my $self = shift;
    $self->stash(
        body_class => 'page_index',
        tags       => $self->dists->tags->{by_count},
    );
}

sub _parse_search_options {
    my ($self, $q) = @_;
    my %opts;
    $q =~ s/ \s*\b author: (?: (['"]?)(.+)\1) \s*//xig
        and $opts{author} = +{ type => $1||"'", q => CORE::fc $2 };

    $q =~ s/ \s*\b from: (.+) \s*//xig
        and $opts{dist_source} = $1;

    return (\%opts, $q);
}

sub search {
    my $self = shift;
    return $self->lucky if $self->param('lucky');

    my @dists;
    if (length (my $q = $self->param('q'))) {
        (my $opts, $q) = $self->_parse_search_options($q);

        @dists = length $q
            ? (uniq_by { $_->{meta_url} } (
                 $self->dists->find({ name        => \$q })->each,
                 $self->dists->find({ description => \$q })->each
            )) : $self->dists->find->each;

        @dists = grep $_->{author_id} =~ /\Q$opts->{author}{q}\E/i, @dists
            if $opts->{author} and $opts->{author}{type} eq "'";

        @dists = grep CORE::fc($_->{author_id}) eq $opts->{author}{q}, @dists
            if $opts->{author} and $opts->{author}{type} eq '"';

        @dists = grep lc($_->{dist_source}) eq $opts->{dist_source}, @dists,
            if $opts->{dist_source};
    }
    else {
        @dists = $self->dists->find->each;
    }

    @dists = nsort_by { -$_->{stars} } @dists;

    for (@dists) {
        $_->{date_updated} = $_->{date_updated}
            ? strftime '%Y-%m-%d', gmtime $_->{date_updated}
            : 'N/A';

        $_->{travis_url} = Mojo::URL->new($_->{url})->host('travis-ci.org');
    }

    my $active_tag = uc($self->param('tag') // '');
    @dists = grep { grep $_ eq $active_tag, @{ $_->{tags} } } @dists
        if $active_tag;

    my $tags = $self->dists->tags;
    my %data = (
        is_active_weak_tag => (
            scalar grep {
                $_->{is_weak} and $_->{tag} eq $active_tag
            } @{ $tags->{all} }
        ),
        tags  => $tags->{by_count},
        dists => \@dists,
        body_class => 'page_search',
    );

    $self->respond_to(
        html => { %data, template => 'root/search' },
        json => { json => { dists => \@dists } },
    );
}

sub lucky {
    my $self = shift;

    my $q = $self->param('q') // '';
    my @dists = $self->dists->find({ name        => \$q })->each,
                $self->dists->find({ description => \$q })->each;
    @dists or return $self->reply->not_found;

    my $dist = (grep $_->{name} eq $q, @dists)[0]
         || (nsort_by { -$_->{stars} } @dists)[0];

    $self->redirect_to(dist => dist => $dist->{name});
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
