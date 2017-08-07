package ModulesPerl6::Controller::Todo;

use Mojo::Base 'Mojolicious::Controller';

use List::UtilsBy qw/sort_by  nsort_by/;
use List::Util qw/sum/;
use experimental 'postderef';

sub index {
    my $self = shift;

    my $auth = $self->stash('author');;
    my $dists = $self->dists->find
        ->grep(sub {
            scalar $_->{problems}->@*
            and (not length $auth or $_->{author_id} =~ /\Q$auth\E/i)
        })
        ->each(sub {
            $_->{author_id} =~ s/\s*<[^>]+>|\S+\@\S+//; # toss email addresses
            $_->{problems}->@*
            =   nsort_by { -$_->{severity} }
                 sort_by {  $_->{problem}  }
                    $_->{problems}->@*
        })
        ->sort(sub {
                sum(map $_->{severity}, $b->{problems}->@*)
            <=> sum(map $_->{severity}, $a->{problems}->@*)
        });

    $self->respond_to(
        html => { dists => $dists, template => 'todo/index' },
        json => { json => { dists => $dists } },
    );
}

1;

__END__

=encoding utf8

=for stopwords NIY dists

=head1 NAME

ModulesPerl6::Controller::Todo- controller handling the todo lists for modules
