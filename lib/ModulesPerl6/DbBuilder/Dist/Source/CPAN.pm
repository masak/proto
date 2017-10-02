package ModulesPerl6::DbBuilder::Dist::Source::CPAN;

use base 'ModulesPerl6::DbBuilder::Dist::Source';

use File::Spec::Functions qw/catfile/;
use ModulesPerl6::DbBuilder::Log;
use Mew;
use Mojo::File qw/path/;
use experimental 'postderef';

use constant LOCAL_CPAN_DIR => 'dists-from-CPAN';

sub re {
    qr{
        ^   cpan?://
            (               # file
                id/\S/\S\S/
                ([^/]+)     # author
                /Perl6/
                (\S+)       # dist
            )
        $
    }ix;
}

sub load {
    my $self = shift;
    my $dist = $self->_dist or return;
    my ($file, $author, $basename) = $self->_meta_url =~ $self->re;
    $file = catfile LOCAL_CPAN_DIR, $file;

    $dist->{dist_source} = 'cpan';
    $dist->{author_id} = $author;

    $dist->{date_updated} = (stat $file)[9]; # mtime
    $dist->{name} ||= $basename =~ s/-[^-]+$//r;

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

1;

__END__
