package P6Project::Stats;

use strict;
use warnings;
use 5.010;

sub new {
  my ($class) = @_;
  my $self = {
    'success' => 0,
    'failed' => 0,
    'errors' => [],
  };
  return bless $self, $class;
}

sub error {
  my ($self, $error) = @_;
  push @{$self->{errors}}, $error;
  $self->{failed}++;
}

sub succeed {
  my ($self) = @_;
  $self->{success}++;
}

sub success {
  my ($self) = @_;
  return $self->{success};
}

sub failed {
  my ($self) = @_;
  return $self->{failed};
}

sub errors {
  my ($self) = @_;
  return @{$self->{errors}};
}

1;
