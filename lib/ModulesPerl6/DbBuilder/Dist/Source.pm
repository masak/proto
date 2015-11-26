package ModulesPerl6::DbBuilder::Dist::Source;

use strictures 2;

use File::Spec::Functions qw/catfile/;
use JSON::Meth qw/$json/;
use Mojo::UserAgent;
use Mojo::Util qw/spurt/;
use Try::Tiny;
use Types::Standard qw/InstanceOf  Maybe  Ref  Str/;

use ModulesPerl6::DbBuilder::Log;

use Moo;
use namespace::clean;

has _logos_dir => (
    init_arg => 'logos_dir',
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has _dist => (
    is => 'lazy',
    isa => Maybe[Ref['HASH'] | InstanceOf['JSON::Meth']],
    default => sub {
        my $self = shift; $self->_parse_meta( $self->_download_meta );
    },
);

has _dist_db => (
    init_arg => 'dist_db',
    is       => 'ro',
    isa      => InstanceOf['ModulesPerl6::Model::Dists'],
    required => 1,
);

has _meta_url => (
    init_arg => 'meta_url',
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has _ua => (
    is      => 'lazy',
    isa     => InstanceOf['Mojo::UserAgent'],
    default => sub { Mojo::UserAgent->new( max_redirects => 10 ) },
);

sub _download_meta {
    my $self = shift;
    my $url = $self->_meta_url;

    log info => "Downloading META file from $url";
    my $tx = $self->_ua->get( $url );

    if ( $tx->success ) { return $tx->res->body }
    else {
        my $err = $tx->error;
        log error => "$err->{code} response: $err->{message}" if $err->{code};
        log error => "Connection error: $err->{message}";
    }

    return;
}

sub _parse_meta {
    my ( $self, $data ) = @_;

    log info => 'Parsing META file';
    eval { $data or die "No data to parse\n"; $data->$json };
    if ( $@ ) { log error => "Failed to parse: JSON error: $@"; return; }

    length $json->{ $_ } or log warn => "Required `$_` field is missing"
        for qw/perl  name  version  description  provides/;

    $json->{url}
             = $json->{'source-url'}
            // $json->{'repo-url'}
            // $json->{support}{source};

    return $self->_fill_missing( $json );
}

sub _fill_missing {
    my ( $self, $dist ) = @_;

    my $old_dist_data;
    if ( length $dist->{name} ) {
        $old_dist_data
        = $self->_dist_db->find({ name => $dist->{name} })->first;
        $old_dist_data and delete $old_dist_data->{logo};
    }

    delete @$dist{qw/author_id  stars  issues  date_updated  date_added/};
    %$dist = (
        name          => 'N/A',
        author_id     =>
            $dist->{author}
            // (ref $dist->{authors} ? $dist->{authors}[0] : $dist->{authors})
            // 'N/A',
        url           => 'N/A',
        description   => 'N/A',
        stars         => 0,
        issues        => 0,
        date_updated  => 0,
        date_added    => 0,

        %{ $old_dist_data || {} },
        %$dist,

        # Kwalitee metrics
        has_readme    => 0,
        has_tests     => 0,
        panda         => $dist->{'source-url'} && $dist->{provides}
                            ? 2 : $dist->{'source-url'} ? 1 : 0,

        _builder      => {}, # key used only during build process to store data
    );

    return $dist;
}

sub _save_logo {
    my ( $self, $size ) = @_;
    my $dist = $self->_dist;
    return unless defined $size and $dist and $dist->{name} ne 'N/A';
    log info => "Dist has a logotype of size $size bytes.";

    my $logo
    = catfile $self->_logos_dir, 's-' . $dist->{name} =~ s/\W/_/gr . '.png';
    return 1 if -e $logo and -s $logo == $size; # 99% we already got that logo

    log info => 'Did not find cached dist logotype. Downloading.';
    my $repo_root = $self->_meta_url =~ s{[^/]+$}{}r;
    my $tx = $self->_ua->get("$repo_root/logotype/logo_32x32.png");

    unless ( $tx->success ) {
        my $err = $tx->error;
        log error => "$err->{code} response: $err->{message}" if $err->{code};
        log error => "Connection error: $err->{message}";
        return;
    }

    spurt $tx->res->body => $logo;
    return 1;
}

sub _set_readme {
    my ( $self, @files ) = @_;
    my %readmees = map +( "README$_" => 1 ), '', # just 'README'; no ext.
        qw/.pod  .pod6  .md        .mkdn  .mkd  .markdown  .mkdown  .ron
           .rst  .rest  .asciidoc  .adoc  .asc  .txt/;

    my $dist = $self->_dist or return;
    $dist->{has_readme} = grep( $readmees{$_}, @files ) ? 1 : 0;

    $self;
}

sub _set_tests {
    my ( $self, @files ) = @_;
    my %tests = map +( $_ => 1 ), qw/t  test  tests/;

    my $dist = $self->_dist or return;
    $dist->{has_tests} = grep( $tests{$_}, @files ) ? 1 : 0;

    $self;
}

sub load { ... }
sub re   { ... }

1;

__END__

=encoding utf8

=for stopwords md dist dists

=head1 NAME

ModulesPerl6::DbBuilder::Dist::Source - base class for distribution sources

=head1 SYNOPSIS

    use base 'ModulesPerl6::DbBuilder::Dist::Source';

    sub re { qr{^https?://\Qraw.githubusercontent.com\E/([^/]+)/([^/]+)}i }

    sub load {
        my $self = shift;
        my $dist = $self->_dist or return;
        ...
        do stuff
    }

=head1 DESCRIPTION

A I<Dist Source> is an accessible location where files for a Perl 6
distribution are hosted, such as a GitHub repository. This base class defines
interface and provides utility methods for classes that add support for
an arbitrary dist source.

=head1 CONVENTIONS

=hea2 logotype filenames

    Some::Awesome::Dist => s-Some__Awesome__Dist.png
    # You can use:
    my $logo_filename = 's-' . $dist_name =~ s/\W/_/gr . '.png';

When downloading dist logotypes, the subclass must derive the the filename
by converting each C<\W> character to an underscore, prefixing the result
with C<s->, and postfixing it with C<.png>

=head2 sharing data during build process

    $self->_dist->{_builder}{has_travis} = 1;

Some build L<postprocessors|ModulesPerl6::DbBuilder::Dist::PostProcessor>
can be communicated with using the C<_builder> key in the L</_dist> hashref.
It will be deleted after all postprocessors are run, before dist is added
to the database. Check the documentation for the postprocessor you're
interested in to learn how to activate its run for your dists.

=head1 CONSTRUCTOR ARGUMENTS

    My::Awesome::Dist::Source->new(
        meta_url  => 'https://example.com/user/repo/master/META.info',
        logos_dir => 'public/content-pics/dist-logos',
        dist_db   => ModulesPerl6::Model::Dists->new,
    );

Several arguments will be provided by the main build script to the subclassed
Dist Source. These are:

=head2 C<metal_url>

See L</_meta_url> private attribute.

=head2 C<logos_dir>

See L</_logos_dir> private attribute.

=head2 C<dist_db>

See L</_dist_db> private attribute.

=head1 PROVIDED PUBLIC METHODS

=head2 C<re>

    sub re { ... }

    # Subclass:
    sub re { qr{^https?://\Qraw.githubusercontent.com\E/([^/]+)/([^/]+)}i }

This method is a stub and must be overriden by subclasses. No assumption
shall be made about provided arguments. The method must return a C<Regexp>
reference that matches the C<META> file URL of dists hosted on this particular
Dist Source.

=head2 C<load>

    sub load { ... }

    # Subclass:
    sub load {
        my $self = shift;
        my $dist = $self->_dist or return;
        do_stuff_with_dist($dist);

        return $dist;
    }

This method is a stub and must be overriden by subclasses. No arguments,
other than the invocant, are given to the method. The method must return
C<undef> (if, say, an error occured) or a hashref describing the dist.
See L</_fill_missing> private method for details on keys/values.

=head1 PRIVATE ATTRIBUTES

=head2 C<_logos_dir>

    use File::Spec::Functions qw/catfile/;
    download_logo
        unless $repo_logo_size == -s catfile $self->_logos_dir, $logo_filename;

Contains path where distribution's logotype files are stored. If possible, the
subclass must check whether a cached logotype already exists before downloading
the file again (e.g. by comparing the size of the file on disk with the
size advertisized by repo's API, if that exists) See L</CONVENTIONS> section
for details on file naming.

=head2 C<_dist>

    $self->_dist->{name} = 'My::Awesome::Dist';

This is a lazily instantiated attribute that on first access calls
L</_download_meta> and then L</_parse_meta> and returns the result. Use this
as the skeleton for your dist info, as well as to check whether dist
already exists in the database and when it was last updated (e.g. to abort
extra work if last updated time matches last commit time in repo).

The keys and default values in the C</_dist> hashref are as follows:

    %$dist = (
        name          => 'N/A',
        author_id     =>
            $dist->{author}
            // (ref $dist->{authors} ? $dist->{authors}[0] : $dist->{authors})
            // 'N/A',
        url           => 'N/A',
        description   => 'N/A',
        stars         => 0,
        issues        => 0,
        date_updated  => 0,
        date_added    => 0,

        %{ $old_dist_data || {} },
        %$dist,

        # Kwalitee metrics
        has_readme    => 0,
        has_tests     => 0,
        panda         => $dist->{'source-url'} && $dist->{provides}
                            ? 2 : $dist->{'source-url'} ? 1 : 0,

        _builder      => {},
    );

=head3 Keys From META File

First of all, keys that do not conflict with build

has _dist => (
    is => 'lazy',
    isa => Maybe[Ref['HASH'] | InstanceOf['JSON::Meth']],
    default => sub {
        my $self = shift; $self->_parse_meta( $self->_download_meta );
    },
);

has _dist_db => (
    init_arg => 'dist_db',
    is       => 'ro',
    isa      => InstanceOf['ModulesPerl6::Model::Dists'],
    required => 1,
);

has _meta_url => (
    init_arg => 'meta_url',
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has _ua => (
    is      => 'lazy',
    isa     => InstanceOf['Mojo::UserAgent'],
    default => sub { Mojo::UserAgent->new( max_redirects => 10 ) },
);

=head1 CONTACT INFORMATION

Original version of this module was written by Zoffix Znet
(L<https://github.com/zoffixznet/>, C<Zoffix> on irc.freenode.net).

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.

