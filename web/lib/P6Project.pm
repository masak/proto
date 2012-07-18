package P6Project;

use strict;
use warnings;
use 5.010;

use Mojo::UserAgent;
use P6Project::Stats;
use Encode qw(encode_utf8);
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
  $self->{info} = P6Project::Info->new(p6p=>$self);
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
  open my $f, '>', $self->output_dir . $filename or die "Cannot open '$filename' for writing: $!";
  print { $f } $file->res->body;
  close $f or warn "Error while closing file '$filename': $!";
  return 1;
}

sub writeout {
  my ($self, $content, $filename, $encode) = @_;
  if ($encode) {
    $content = encode_utf8($content);
  }
  write_file($self->output_dir . $filename, {binmode => ':encoding(UTF-8)'}, $content);
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
  my $content = $self->html->get_html($self->projects);
  return $self->writeout($content, $filename, 1);
}

sub write_json {
  my ($self, $filename) = @_;
  my $content = encode_json($self->projects);
  return $self->writeout($content, $filename);
}

1;
