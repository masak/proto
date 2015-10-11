package P6Project;

use strict;
use warnings;
use 5.010;

use Mojo::UserAgent;
use P6Project::Stats;
use Encode qw(decode_utf8);
use P6Project::Info;
use P6Project::HTML;
use JSON;
use File::Slurp;

sub new {
    my ($class, %opts) = @_;
    my $self = \%opts;
    $self->{output_dir} //= './';
    my $ua = Mojo::UserAgent->new;
    $ua->connect_timeout(10);
    $ua->request_timeout(10);
    $self->{ua} = $ua;
    $self->{stats} = P6Project::Stats->new;
    bless $self, $class;
    $self->{info} = P6Project::Info->new(p6p=>$self, limit=>$self->{limit});
    $self->{html} = P6Project::HTML->new(p6p=>$self);
    $self->{projects} = {};
    return $self;
}

sub ua {
    my ($self) = @_;
    return $self->{ua};
}

sub stats {
    my ($self) = @_;
    return $self->{stats};
}

sub output_dir {
    my ($self) = @_;
    return $self->{output_dir};
}

sub getstore {
    my ($self, $url, $filename) = @_;
    my $file = $self->ua->get($url);
    if (!$file->success) { return 0; }
    my $path = $self->output_dir . $filename;
    open my $f, '>', $path or die "Cannot open '$path' for writing: $!";
    print { $f } $file->res->body;
    close $f or warn "Error while closing file '$filename': $!";
    return 1;
}

sub writeout {
    my ($self, $content, $filename) = @_;
    my $decoded_content = eval { decode_utf8($content) };
    if ($@) {
        warn "Error decoding content: $@";
        $decoded_content = $content;
    }
    write_file($self->output_dir . $filename,
               {binmode => ':encoding(UTF-8)', atomic => 1},
               $decoded_content);
}

sub info {
    my ($self) = @_;
    return $self->{info};
}

sub html {
    my ($self) = @_;
    return $self->{html};
}

sub min_popular {
    my ($self) = @_;
    return $self->{min_popular};
}

sub load_projects {
    my ($self, $url) = @_;
    $self->{projects} = $self->info->get_projects($url);
}

sub projects {
    my ($self) = @_;
    return $self->{projects};
}

sub template {
    my ($self) = @_;
    return $self->{template};
}

sub write_html {
    my ($self, $filename) = @_;

    my $projects = $self->projects;
    my @projects = keys %{$projects};
    @projects = sort projects_list_order @projects;
    @projects = map { $projects->{$_} } @projects;
    for ( @projects ) {
        $_->{description} ||= 'N/A';
        $_->{last_updated} =~ s/T.+//;
    }
    my $content = $self->html->get_html(\@projects);
    return $self->writeout($content, $filename);
}

sub write_recent {
    my ($self, $filename) = @_;

    my $projects = $self->projects;
    my @projects = keys %{$projects};
    @projects = reverse sort {
        ($projects->{$a}{last_updated}||'')
            cmp
        ($projects->{$b}{last_updated}||'')
    } @projects;
    @projects = map { $projects->{$_} } @projects;
    $_->{description} ||= 'N/A' for @projects;
    my $content = $self->html->get_html(\@projects);
    return $self->writeout($content, $filename);
}

sub write_json {
    my ($self, $filename) = @_;

    my $projects = $self->projects;
    for my $mod ( values %$projects ) { # use JSON's true/false values
        $mod = +{ %$mod };
        $mod->{$_} = $mod->{$_} ? JSON::true : JSON::false
            for qw/
                badge_has_tests  badge_is_fresh  badge_panda_nos11
                badge_panda      badge_is_popular
            /;
        $mod->{badge_has_readme} //= JSON::false;
    }
    return $self->writeout(encode_json($projects), $filename);
}

sub projects_list_order {
  my $prj1 = $a;
  my $prj2 = $b;

  $prj1 =~ s{^perl6-}{}i;
  $prj2 =~ s{^perl6-}{}i;

  return lc($prj1) cmp lc($prj2);
}


1;
