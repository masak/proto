package ModulesPerl6::DbBuilder::Dist::PostProcessor::p30METAChecker;

use strictures 2;
use base 'ModulesPerl6::DbBuilder::Dist::PostProcessor';

use Mojo::UserAgent;
use Mojo::Util qw/b64_decode/;
use ModulesPerl6::DbBuilder::Log;
use List::UtilsBy qw/uniq_by/;
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
        push @problems, problem 'Missing MANIFEST file', 3
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

    length $dist->{ $_ } or push @problems,
        problem qq|Missing required "$_" field in META file|, 5
    for qw/perl  name  version  description  provides/;

    push @problems, problem 'META file does not have a "tags" field', 1
        unless $dist->{tags}->@*;

    if ($dist->{version}) {
        push @problems, problem 'Invalid version "*" in META file', 5
            if $dist->{version} eq '*';
    }
    else {
        push @problems, problem 'No version in META file', 5;
    }

    $dist->{problems} = [uniq_by { $_->{problem} } @problems];
}

sub _check_todo_problem_author {
    my ($self, $dist) = @_;

    my $author = $dist->{author} // $dist->{authors};
    $author = $author->[0] if ref $author eq 'ARRAY';

    return if length $author;
    problem "No author listed in META file", 3
}

sub _check_todo_problem_readme {
    my ($self, $dist, $files) = @_;

    my ($readme) = grep $_->{name} =~ /^README/, @$files
        or return problem 'Missing README file', 1;

    # If we failed to fetch the README content, return any cached README
    # problems, as otherwise we'd be flopping on reporting these README issues,
    # whenever network problems occur.
    return grep $_->{problem} =~ /\bREADME\b/, ($dist->{problems} || [])->@*
        if $readme->{error};

    return unless $readme->{content} =~ /\b(panda|ufo)\b/;
    problem 'README mentions discouraged tools (panda or ufo)', 2
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
