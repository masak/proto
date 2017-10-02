package ModulesPerl6::Controller::Dist;

use File::Spec::Functions qw/catfile/;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON qw/from_json/;
use experimental 'postderef';

use constant UNPACKED_DISTS => 'dists-from-CPAN-unpacked';

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

    my $dist = $dists->first;
    my ($files_dir, $files)
    = (from_json $dist->{files})->@{qw/files_dir  files/};

    $dist->{files} = [
        sort {
               $b->{is_dir} <=> $a->{is_dir}
            or $a->{name}   cmp $b->{name}
        }
        map {
            my $raw = catfile UNPACKED_DISTS, $files_dir, $_;
            +{
                raw    => $raw,
                is_dir => (-d $raw ? 1 : 0),
                name   => $_,
            }
        } keys %{ $files || {} }
    ];
    $self->stash(dist => $dist);
}

1;

__END__
