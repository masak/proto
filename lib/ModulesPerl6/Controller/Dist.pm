package ModulesPerl6::Controller::Dist;

use File::Spec::Functions qw/catfile  splitdir/;
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

    my $file_prefix = $self->stash('file');
    if (length $file_prefix) {
        my @pieces = splitdir $file_prefix;
        while (@pieces) {
            my $piece = shift @pieces;
            return $self->reply->not_found
                unless exists $files->{$piece};
            $files = $files->{$piece};
        }
    }

    unless (keys %{ $files || {} }) {
        # we're either in an empty dir or user wants a file

        my $full = catfile UNPACKED_DISTS, $files_dir,
            (length $file_prefix ? $file_prefix : ());

        # go up one level from `public`; probably should do something saner
        $self->reply->static(catfile '..', $full) if -f $full;
    }

    $dist->{files} = [
        sort {
               $b->{is_dir} <=> $a->{is_dir}
            or $a->{name}   cmp $b->{name}
        }
        map {
            my $full = catfile +(length $file_prefix ? $file_prefix : ()), $_;
            my $real = catfile UNPACKED_DISTS, $files_dir, $full;
            +{
                full   => $full,
                is_dir => (-d $real ? 1 : 0),
                name   => $_,
            }
        } keys %{ $files || {} }
    ];
    $self->stash(
        dist => $dist,
        files_dir => $files_dir,
        file_prefix => $file_prefix);
}

1;

__END__
