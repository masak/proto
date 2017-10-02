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
        ^   cpan?://id/\S/\S\S/
            ([^/]+) # author
            /Perl6/
            (\S+) # dist
        $
    }ix;

    # cpan://id/T/TA/TADZIK/Perl6/Acme-Meow-0.1.meta
}

sub load {
    my $self = shift;

    log info => 'Fetching distro info and commits';
    my $dist    = $self->_dist or return;

    $dist->{dist_source} = 'cpan';

    $dist->{author_id} = $dist->{_builder}{repo_user}
        if $dist->{author_id} eq 'N/A';

    $dist->{date_updated} = undef;
    return if $dist->{name} eq 'N/A';

    $dist->{_builder}{is_fresh} = 1;
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
