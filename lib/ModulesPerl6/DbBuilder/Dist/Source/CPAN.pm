package ModulesPerl6::DbBuilder::Dist::Source::CPAN;

use base 'ModulesPerl6::DbBuilder::Dist::Source';

use Archive::Any;
use File::Spec::Functions qw/catfile  splitdir/;
use File::Basename qw/fileparse/;
use File::Copy qw/move/;
use File::Glob qw/bsd_glob/;
use File::Path qw/make_path  remove_tree/;
use File::Temp qw/tempdir/;
use List::Util qw/uniq/;
use ModulesPerl6::DbBuilder::Log;
use Mew;
use Mojo::File qw/path/;
use Mojo::JSON qw/to_json/;
use Text::FileTree;
use experimental 'postderef';

use constant LOCAL_CPAN_DIR => 'dists-from-CPAN';
use constant UNPACKED_DISTS => 'dists-from-CPAN-unpacked';

sub re {
    qr{
        ^   cpan?://
            (               # file
                id/
                (           # dist dir portion
                    [A-Z]/[A-Z]{2}/
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
    $dist_dir = catfile $dist_dir, $basename =~ s/.meta$//r;
    $file = catfile LOCAL_CPAN_DIR, $file;

    $dist->{dist_source} = 'cpan';
    $dist->{author_id} = $author;
    $dist->{date_updated} = (stat $file)[9]; # mtime
    $dist->{name} ||= $basename =~ s/-[^-]+$//r;

    my @files = $self->_extract($file, catfile UNPACKED_DISTS, $dist_dir);
    $dist->{files} = to_json +{
        files_dir => $dist_dir,
        files     => Text::FileTree->new->parse(
            join "\n", map { catfile grep length, splitdir $_ } @files
        ),
    };

    $dist->{_builder}{post}{no_meta_checker} = 1;

    return $dist;
}

sub _to_file_tree {
    my ($self, @files) = @_;

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

    my $extraction_dir = tempdir;
    $archive->extract($extraction_dir);

    my @files;
    if ($archive->is_impolite) {
        move $extraction_dir, $dist_dir;
        @files = $archive->files;
    }
    else {
        move +(bsd_glob "$extraction_dir/*")[0], $dist_dir;
        @files = map {
            my @bits = splitdir $_;
            shift @bits;
            catfile @bits;
        } $archive->files;
    }

    grep length, uniq @files;
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


1;

__END__
