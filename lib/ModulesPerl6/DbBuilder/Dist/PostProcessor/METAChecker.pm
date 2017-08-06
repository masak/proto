package ModulesPerl6::DbBuilder::Dist::PostProcessor::METAChecker;

use strictures 2;
use base 'ModulesPerl6::DbBuilder::Dist::PostProcessor';

use Mojo::UserAgent;
use Mojo::Util qw/b64_decode/;
use ModulesPerl6::DbBuilder::Log;
use experimental 'postderef';

sub problem {
    my ($problem, $severity) = @_;
    { problem => $problem, severity => $severity }
}

sub process {
    my $self = shift;
    my $dist = $self->_dist;

    $self->_check_meta_url($dist);
    $self->_check_todo_problems($dist);

    return 1;
}

sub _check_todo_problems {
    my ($self, $dist) = @_;

    my @problems;
    if (my @files = ($dist->{_builder}{files} || [])->@*) {
        push @problems, $self->_check_todo_problem_readme($dist, \@files);
        push @problems, problem 'dist has no MANIFEST file', 3
            if $dist->{dist_source} eq 'cpan'
                and not grep $_ eq 'MANIFEST', @files;
    }
    else {
        # If we're here that can mean the dist was processed in abridged,
        # cached mode; pick existing readme/manifest problems from cached
        # data, if we got 'em in it
        @problems = grep $_->{problem} =~ /\b(README|MANIFEST)\b/,
            ($dist->{problems} || [])->@*;
    }

    push @problems, $self->_check_todo_problem_author($dist);

    length $dist->{ $_ }
        or push @problems, problem "required `$_` field is missing", 5
    for qw/perl  name  version  description  provides/;

    push @problems, problem 'dist does not have any tags', 1
        unless $dist->{tags}->@*;

    if ($dist->{version}) {
        push @problems, problem "dist has `*` version (it's invalid)", 5
            if $dist->{version} eq '*';
    }
    else {
        push @problems, problem 'dist does not have a version set', 5;
    }

    $dist->{problems} = \@problems;
}

sub _check_todo_problem_author {
    my ($self, $dist) = @_;

    my $author = $dist->{author} // $dist->{authors};
    $author = $author->[0] if ref $author eq 'ARRAY';

    return if length $author;
    problem "dist has no author(s) specified", 3
}

sub _check_todo_problem_readme {
    my ($self, $dist, $files) = @_;

    my ($readme) = grep $_->{name} =~ /^README/, @$files
        or return problem 'dist has no README', 1;

    my $content = eval {
        Mojo::UserAgent->new( max_redirects => 5 )
            ->get( $readme->{url} )->result->json
    };
    if ($@) {
        log error => "Failed to fetch README content from $readme->{url}: $@";
        return;
    }

    # TODO XXX: the JSON+decode step is valid for GitHub, but
    # if other dist sources are taught to provide READMEs, they
    # may have other mechanism that will need to be taken care of
    # here. You can use $dist->{dist_source} to find out which
    # dist source the dist came from.

    # Possible encodings are 'utf-8' and 'base64', per
    # https://developer.github.com/v3/git/blobs/#parameters
    $content = $content->{encoding} eq 'base64'
        ? (b64_decode $content->{content})
        :             $content->{content};

    return unless $content =~ /\b(panda|ufo)\b/;
    problem 'dist mentions discouraged tools (panda or ufo) in the README', 2
}

sub _check_meta_url {
    my ($self, $dist) = @_;

    my $repo_url = 'https://github.com/'
        . join '/', grep length, @{ $dist->{_builder} }{qw/repo_user  repo/};

    if ( $repo_url eq $dist->{url} ) {
        log info => "dist source URL is same as META repo URL ($repo_url)";
        return;
    }

    my $code = Mojo::UserAgent->new( max_redirects => 5 )
        ->get( $dist->{url} )->res->code;

    log +( $code == 200 ? 'info' : 'error' ),
        "HTTP $code when accessing dist source URL ($dist->{url})";
}

1;

__END__

=encoding utf8

=for stopwords md dist dists

=head1 NAME

ModulesPerl6::DbBuilder::Dist::PostProcessor::METAChecker - postprocessor that checks META6.json info is correct

=head1 CONTACT INFORMATION

Original version of this module was written by Zoffix Znet
(L<https://github.com/zoffixznet/>, C<Zoffix> on irc.freenode.net).

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
