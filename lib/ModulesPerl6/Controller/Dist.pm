package ModulesPerl6::Controller::Dist;

use File::Spec::Functions qw/catfile  splitdir/;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON qw/from_json/;
use Mojo::File qw/path/;
use Mojo::Util qw/decode/;
use experimental 'postderef';

use constant UNPACKED_DISTS => 'dists-from-CPAN-unpacked';

sub dist {
    my $self = shift;
    return $self->_fetch_dist;
}

sub raw {
    my $self = shift;
    return $self->_fetch_dist(raw => 1);
}

sub _fetch_dist {
    my $self = shift;
    my %args = @_;
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

    my $wanted_file;
    unless (keys %{ $files || {} }) {
        # we're either in an empty dir or user wants a file

        $wanted_file = catfile UNPACKED_DISTS, $files_dir,
            (length $file_prefix ? $file_prefix : ());
        $wanted_file = undef unless -f $wanted_file;
    }

    if ($wanted_file) {
        # go up one level from `public`; probably should do something saner
        return $self->reply->static(catfile '..', $wanted_file)
            if $args{raw} or -B $wanted_file;

        $self->stash(
            show_file    => 1,
            file_type    => (($wanted_file =~ /\.(p6|pm6|pm|pl6|pl)$/)
                ? 'perl6' : 'plain'),
            file_content => decode 'UTF-8', path($wanted_file)->slurp);
    }
    else {
        $dist->{files} = [
            sort {
                   $b->{is_dir} <=> $a->{is_dir}
                or $a->{name}   cmp $b->{name}
            }
            map {
                my $full = catfile
                    +(length $file_prefix ? $file_prefix : ()), $_;
                my $real = catfile UNPACKED_DISTS, $files_dir, $full;
                +{
                    full   => $full,
                    is_dir => (-d $real ? 1 : 0),
                    name   => $_,
                }
            } keys %{ $files || {} }
        ];
    }

    my @up_dir_parts = splitdir $file_prefix;
    pop @up_dir_parts;
    $self->stash(
        dist        => $dist,
        files_dir   => $files_dir,
        distro_str  => (splitdir $files_dir)[-1],
        file_prefix => $file_prefix,
        up_dir      => $self->dist_url_for(
            $dist, file => catfile(@up_dir_parts) // ''
        ),
    );
}

1;

__END__
