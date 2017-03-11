package ModulesPerl6::DbBuilder::Dist::Source;

use FindBin; FindBin->again;
use File::Spec::Functions qw/catfile/;
use JSON::Meth qw/$json/;
use Mojo::JSON qw/from_json/;
use Mojo::UserAgent;
use Mojo::Util qw/slurp  spurt  decode/;
use Try::Tiny;

use ModulesPerl6::DbBuilder::Log;
use Mew;

has _logos_dir => Str;
has _dist_db   => InstanceOf['ModulesPerl6::Model::Dists'];
has _meta_url  => Str;
has _dist      => Maybe[Ref['HASH']], (
    is      => 'lazy',
    default => sub {
        my $self = shift; $self->_parse_meta( $self->_download_meta );
    },
);
has _ua => InstanceOf['Mojo::UserAgent'], (
    is      => 'lazy',
    default => sub { Mojo::UserAgent->new( max_redirects => 10 ) },
);
has _tag_aliases => Maybe[Ref['HASH']], (
    is => 'lazy',
    default => sub {
        my $raw_tags = eval {
            from_json slurp $ENV{MODULESPERL6_TAG_ALIASES_FILE}
                // catfile $FindBin::Bin, qw/.. tag-aliases.json/;
        } || do { warn "\n\nFailed to load tag-aliases.json: $@\n\n"; exit; };

        my %tags;
        for my $key (keys %{ $raw_tags->{replacements} || {}}) {
            for (@{$raw_tags->{replacements}{$key}}) {
                $tags{+uc} = uc $key;
            }
        }
        my %no_index = map +((uc) => 1), @{ $raw_tags->{do_not_index} || [] };
        { no_index => \%no_index, replacements => \%tags }
    }
);

sub _download_meta {
    my $self = shift;
    my $url = $self->_meta_url;

    log info => "Downloading META file from $url";
    my $tx = $self->_ua->get( $url );

    if ( $tx->success ) { return $tx->res->body }
    else {
        my $err   = $tx->error;
        log error => $err->{code} ? "$err->{code} response: $err->{message}"
                                  : "Connection error: $err->{message}";
    }

    return;
}

sub _parse_meta {
    my ( $self, $data ) = @_;
    length $data or return;
    $data = decode 'utf8', $data;

    log info => 'Parsing META file';
    eval { $data->$json };
    if ( $@ ) { log error => "Failed to parse: JSON error: $@"; return; }

    length $json->{ $_ } or log warn => "Required `$_` field is missing"
        for qw/perl  name  version  description  provides/;

    $json->{url}
             = $json->{'source-url'}
            // $json->{'repo-url'}
            // $json->{support}{source};

    my ($no_index, $tags) = @{ $self->_tag_aliases }{qw/no_index replacements/};

    $json->{tags} = [] unless ref($json->{tags}) eq 'ARRAY';
    @{ $json->{tags} } = map {
            length > 20 ? substr($_, 0, 17) . '...' : $_
        } map {
            $tags->{$_} || $_ # perform substitution to common form
        } grep {
            length and not ref and not $no_index->{$_}
        } map uc, @{ $json->{tags} };
    return $self->_fill_missing( {%$json} );
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
        author_id     => $self->_get_author( $dist ),
        meta_url      => $self->_meta_url,
        url           => 'N/A',
        description   => 'N/A',
        tags          => [],
        stars         => 0,
        issues        => 0,
        date_updated  => 0,
        date_added    => 0,

        %{ $old_dist_data || {} },
        %$dist,

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
        log error => $err->{code} ? "$err->{code} response: $err->{message}"
                                  : "Connection error: $err->{message}";
        return;
    }

    spurt $tx->res->body => $logo;
    return 1;
}

sub _get_author {
    my ( $self, $dist ) = @_;
    my $author = $dist->{author} // $dist->{authors} // 'N/A';
    $author = $author->[0] if ref $author eq 'ARRAY';

    return $author;
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

=head1 CONVENTIONS AND CAVEATS

=head2 logotype filenames

    Some::Awesome::Dist => s-Some__Awesome__Dist.png
    # You can use:
    my $logo_filename = 's-' . $dist_name =~ s/\W/_/gr . '.png';

When downloading dist logotypes, the subclass must derive the the filename
by converting each C<\W> character to an underscore, prefixing the result
with C<s->, and postfixing it with C<.png>. See also L</_save_logo>.

=head2 sharing data during build process

    $self->_dist->{_builder}{has_travis} = 1;

Some build L<postprocessors|ModulesPerl6::DbBuilder::Dist::PostProcessor>
can be communicated with using the C<_builder> key in the L</_dist> hashref.
It will be deleted after all postprocessors are run, before dist is added
to the database. Check the documentation for the postprocessor you're
interested in to learn how to activate its run for your dists.

One of the keys that a Dist Source should try to set is C<{_builder}{is_fresh}>
that will indicate when the dist has new commits.


=head2 Logging

    use ModulesPerl6::DbBuilder::Log;

    log error => 'Failed to download logo';

Please use L<ModulesPerl6::DbBuilder::Log> to output debugging and
informational messages instead of relying on warn/print.

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
reference that matches the
L<META file|http://design.perl6.org/S22.html#META6.json> URL of dists hosted
on this particular Dist Source.

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

B<Note:> these attributes are private to your subclass. Do not rely on them
from the ouside of it.

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

The keys and default values in the C<_dist> hashref are as follows:

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

        _builder      => {},
    );

=head3 Keys From META File

First of all, all data from
L<META file|http://design.perl6.org/S22.html#META6.json> will be present
(this excludes keys we use during build process, like private L</_builder> store).

=head3 C<_builder>

The hashref containing arbitrary data for communication of Dist Source
subclasses and postprocessors, see L</sharing> data during build process>.

=head3 Dist info keys

    name          => 'N/A',
    author_id     =>
        $dist->{author}
        // (ref $dist->{authors} ? $dist->{authors}[0] : $dist->{authors})
        // 'N/A',
    meta_url      => $self->_meta_url,
    url           => 'N/A',
    description   => 'N/A',
    stars         => 0,
    issues        => 0,
    date_updated  => 0,
    date_added    => 0,

The above are the keys and their defaults for dist info. See documentation
for L<ModulesPerl6::Model::Dists/find> for details.

=head3 Dist info from database

If the dist already exists in the databse, its info will override the defaults
above. See L<ModulesPerl6::Model::Dists/find> for details on what those keys
are.
=head3 C<_dist_db>

    $self->_dist_db->find({ name => $dist->{name} })->first

Provides the L<ModulesPerl6::Model::Dists> object that's used internally
to fetch cached distro data. B<DO NOT USE this object to insert the dist
you're parsing into the database>. Simply return all the info via
L</load> method.

=head3 C<_meta_url>

    my ( $user, $repo ) = $self->_meta_url =~ $self->re;

Returns the URL for dist's
L<META file|http://design.perl6.org/S22.html#META6.json>.

=head3 C<_ua>

    say $self->_ua->get("http://perl6.org")->res->dom->at('title')->all_text;

Returns a L<Mojo::UserAgent> object instantiated with
L<Mojo::UserAgent/max_redirects> set to C<10>.

=head1 PRIVATE METHODS

B<Note:> these methods are private to your subclass. Do not rely on them
from the ouside of it.

=head2 C<_download_meta>

    my $meta_file_data = $self->_download_meta;

I<Your subclass will likely never have to use this method>. It simply
downloads the dist's L<META file|http://design.perl6.org/S22.html#META6.json>
and returns its contents. On error, logs it with
L<ModulesPerl6::DbBuilder::Log> and returns either C<undef> or an empty list,
depending on context. See also L</_dist>.

=head2 C<_get_author>

    my $author_id = $self->_get_author( $dist );

I<Your subclass will likely never have to use this method>. This method
looks through the keys in the hashref given as the argument, which must
represent the L<META file|http://design.perl6.org/S22.html#META6.json>,
and returns the author of the dist or C<N/A> if none were found.

=head2 C<_parse_meta>

    my $dist = $self->_parse_meta( $meta_file_data );

I<Your subclass will likely never have to use this method>. It takes
L<META file|http://design.perl6.org/S22.html#META6.json> data as an argument
and tries to parse it as JSON, L<logging|ModulesPerl6::DbBuilder::Log> any
errors. The method then normalizes the dist URL from possible values in
L<META file|http://design.perl6.org/S22.html#META6.json>, storing it in
C<url> key, calls L</_fill_missing> with the result and returns the result
of that call. See also L</_dist>.

=head2 C<_fill_missing>

    my $dist = $self->_fill_missing( $dist_metadata_hashref );

I<Your subclass will likely never have to use this method>. It takes a
hashref representing dist
L<META file|http://design.perl6.org/S22.html#META6.json> data as the argument,
fills missing keys with defaults and loads cached dist data from the database,
if such exists, and returns the result. See also L</_dist>.

=head2 C<_save_logo>

    $self->_save_logo(
        map $_->{size}, grep $_->{path} eq 'logotype/logo_32x32.png', @$tree
    );

Takes logotype file size, in bytes, as the argument. This value should come
from the repo (for example through queries to an API). Use size of C<0>, if
it is not known. The method won't do anything if size is C<undef> or not
specified.

The method will check whether a logo for the dist of the given size exists
on disk. If not, it will attempt to download one from the repo, by assuming
the removing the L<META file|http://design.perl6.org/S22.html#META6.json>
filename from the end of L</_meta_url> and appending
C</logotype/logo_32x32.png> to it will result in the correct URL to the
logotype file.

Returns C<1> on success (or if a cached version of logo was located), otherwise
returns C<undef> or an empty list, depending on context.

=head1 CONTACT INFORMATION

Original version of this module was written by Zoffix Znet
(L<https://github.com/zoffixznet/>, C<Zoffix> on irc.freenode.net).

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
