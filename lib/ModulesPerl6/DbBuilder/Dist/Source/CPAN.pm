package ModulesPerl6::DbBuilder::Dist::Source::CPAN;

use base 'ModulesPerl6::DbBuilder::Dist::Source';

use Archive::Any;
use File::Spec::Functions qw/catfile/;
use File::Basename qw/fileparse/;
use File::Path qw/make_path  remove_tree/;
use List::Util qw/uniq/;
use ModulesPerl6::DbBuilder::Log;
use Mew;
use Mojo::File qw/path/;
use experimental 'postderef';

use constant LOCAL_CPAN_DIR => 'dists-from-CPAN';
use constant UNPACKED_DISTS => 'dists-from-CPAN-unpacked';

sub re {
    qr{
        ^   cpan?://
            (               # file
                (           # dist dir
                    id/[A-Z]/[A-Z]{2}/
                    ([A-Z]+) # author
                )
                /Perl6/
                (\S+)       # dist
            )
        $
    }ix;
}

sub load {
    my $self = shift;
    my $dist = $self->_dist or return;
    my ($file, $dist_dir, $author, $basename) = $self->_meta_url =~ $self->re;
    $file = catfile LOCAL_CPAN_DIR, $file;

    $dist->{dist_source} = 'cpan';
    $dist->{author_id} = $author;
    $dist->{date_updated} = (stat $file)[9]; # mtime
    $dist->{name} ||= $basename =~ s/-[^-]+$//r;
    $dist->{files} = $self->_extract($file, catfile UNPACKED_DISTS, $dist_dir);

    $dist->{_builder}{post}{no_meta_checker} = 1;

    return $dist;
}

sub _save_logo {}

sub _download_meta {
    my $self = shift;
    my $path = catfile LOCAL_CPAN_DIR,
        substr $self->_meta_url, length 'cpan://';

    log info => "Loading META file from $path";
    if (my $contents = eval { path($path)->slurp }) {
        return $contents;
    } else {
        log error => "Failed to read META file: $@";
        return;
    }
}

sub _extract {
    my ($self, $file, $dist_dir) = @_;
    my $base = $file =~ s/.meta$//r;
    my $archive_file;
    for (qw/.tar.gz  .zip  .tar  .tgz  .tg/) {
        next unless -e "$base$_";
        $archive_file = "$base$_";
        last;
    }
    unless ($archive_file) {
        log error => "Could not find archive for $file";
        return [];
    }

    my $archive = Archive::Any->new($archive_file);
    if ($archive->is_naughty) {
        log error => "Refusing archive that unpacks outside its directory";
        return [];
    };

    remove_tree $dist_dir;
    make_path   $dist_dir;
    -d $dist_dir or return [];
    $archive->extract($dist_dir);
    my @files = $archive->files;
    [uniq @files];
}

1;

__END__
