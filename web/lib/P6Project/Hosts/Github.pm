package P6Project::Hosts::Github;

use strict;
use warnings;
use 5.010;

use Time::Piece;
use Time::Seconds;

my $github_token = do {
    open my $IN, '<', 'github-token'
        or die "Cannot open file 'github-token' for reading: $!";
    my $token = <$IN>;
    chomp $token;
    close $IN;
    $token;
};

sub new {
    my ($class, %opts) = @_;
    my $self = \%opts;
    return bless $self, $class;
}

sub p6p {
    my ($self) = @_;
    return $self->{p6p};
}

sub raw_url {
    'https://raw.githubusercontent.com/';
}

sub api_url {
    'https://api.github.com/';
}

sub web_url {
    'https://github.com/';
}

sub _format_error {
    my ($self, $error) = @_;
    # depending on the version of Mojolicious, $error might either be a hash
    # ref or a string
    if (ref $error) {
        return join ' ', $error->{code}, $error->{message};
    }
    else {
        return $error;
    }
}

sub get_api {
    my ($self, $project, $call) = @_;
    my $url = $self->api_url . "repos/$project->{auth}/$project->{repo_name}";
    if ($call) {
        $url .= $call;
    }
    my $tx = $self->p6p->ua->get($url, {Authorization => "token $github_token"});
    if (! $tx->success ) {
        my $error = $self->_format_error($tx->error);
        $self->p6p->stats->error("Error for project $project->{name} : could not get $url: $error");
        return;
    }
    return $tx->res->json;
}

sub file_url {
    my ($self, $project, $revision, $file) = @_;
    my $url = $self->raw_url . $project->{auth} . '/' . $project->{repo_name} . '/' . $revision;
    $url .= $file;
    return $url;
}

sub blob_url {
    my ($self, $project, $revision, $file) = @_;
    my $url = $self->web_url . $project->{auth} . '/' . $project->{repo_name} . '/blob/' . $revision;
    $url .= $file;
    return $url;
}

sub set_project_info {
    my ($self, $project, $previous) = @_;
    my $ua = $self->p6p->ua;
    my $stats = $self->p6p->stats;

    my $url = $self->web_url . $project->{auth} . '/' . $project->{repo_name} . '/';
    my $tx = $ua->get($url);
    if (! $tx->success ) {
        my $error = $self->_format_error($tx->error);
        $stats->error("Error for project $project->{name} : could not get $url: $error (project probably dead)");
        return 0;
    }
    $project->{url} = $url;

    my $commits = $self->get_api($project, "/commits") or return 0;
    my $latest = $commits->[0];
    my $updated = $latest->{commit}->{committer}->{date};
    $project->{last_updated} = $updated;

    my $ninety_days_ago = localtime() - 90 * ONE_DAY;
    my $is_fresh = $updated && $updated ge $ninety_days_ago->ymd();
    if ($previous && $previous->{last_updated} eq $updated) {
        $previous->{badge_is_fresh} = $is_fresh;
        $previous->{badge_panda} = $project->{badge_panda};
        $previous->{badge_panda_nos11} = $project->{badge_panda_nos11};
        %$project = %$previous;
        print "Not updated since last check, loading from cache\n";
        return 1;
    }
    else {
        $project->{badge_is_fresh} = $is_fresh;
    }
    print "Updated since last check\n";

    my $repo = $self->get_api($project) or return 0;
    $project->{description} //= $repo->{description};

    my $tree = $self->get_api($project, "/git/trees/$latest->{sha}?recursive=1") or return 0;
    my %files = map { $_->{path}, $_->{type} } @{$tree->{tree}};

    ## Get the logo if one exists.
    my $logo_file = 'logotype/logo_32x32.png';
    if ($files{logotype} && $files{$logo_file}) {
        my $logo_name = $project->{name};
        $logo_name =~ s/\W+/_/;
        my $logo_store = "/logos/$logo_name.png";
        ## TODO: check filesize, and skip download if filesize is the same.
        my $logo_url = $self->file_url($project, $latest->{sha}, '/'.$logo_file);
        if ($self->p6p->getstore($logo_url, $logo_store)) {
            $project->{logo} = './'.$logo_store;
            $project->{logo} =~ s{//}{/}g;
        }
    }

    ## And now for some badges.

    $project->{badge_has_tests} = $files{t} || $files{test} || $files{tests};

    my @readmes = grep exists $files{$_}, qw/
    README
    README.pod
    README.pod6
    README.md
    README.mkdn
    README.mkd
    README.markdown
    /;

    $project->{badge_has_readme} = scalar(@readmes) 
    ? $self->blob_url($project, $latest->{sha}, "/$readmes[0]") 
    : undef;

    $project->{badge_is_popular} = $repo->{watchers} && $repo->{watchers} >= $self->p6p->min_popular;

    return 1;
}

1;

# vim: set ts=4 sw=4 expantab
