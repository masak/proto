package P6Project;

use strict;
use warnings;
use 5.010;

use lib '../mojo-app/lib';
use ModulesPerl6::Model::Dists;
use ModulesPerl6::Model::BuildStats;
use constant DB_FILE => 'modulesperl6.db';

#We need ::SSL for Mojo::UserAgent, which is too shy about reporting it missing
use IO::Socket::SSL 1.94;
use Mojo::UserAgent;
use Mojo::Util qw(spurt);
use List::UtilsBy qw(sort_by);
use File::Spec::Functions qw(catdir  catfile);
use P6Project::Stats;
use Encode qw(decode_utf8);
use P6Project::Info;
use P6Project::HTML;
use P6Project::SpriteMaker;
use JSON;
use File::Slurp;
use File::Copy qw/move/;
use Time::Moment;

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

sub no_app_start {
    my ($self) = @_;
    return $self->{no_app_start};
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
        $_->{description}   ||= 'N/A';
        $_->{last_updated}  ||= '';
        $_->{last_updated_full} = $_->{last_updated};
        $_->{last_updated}    =~ s/T.+//;
        ( $_->{logo_sprite} ) = ($_->{logo}//'') =~ m{([^/]+)\.png$};
    }
    my $content = $self->html->get_html(\@projects);

    # NOOP, since we have the app; clean up code later
    return 1; # $self->writeout($content, $filename);
}

sub write_json {
    my ($self, $filename) = @_;

    my $projects = $self->projects;
    for my $mod ( values %$projects ) { # use JSON's true/false values
        $mod = +{ %$mod };
        $mod->{$_} = $mod->{$_} ? JSON::true : JSON::false
            for qw/
                badge_has_tests  badge_panda_nos11
                badge_panda      badge_is_popular
            /;
        $mod->{badge_has_readme} //= JSON::false;
    }

    # For now just have the file remain in the app dir. We'll eventually
    # Have the app handle this stuff.
    spurt encode_json($projects)
        => catfile $self->output_dir, 'public', $filename;

    return 1; #$self->writeout(encode_json($projects), $filename);
}

sub write_sprite {
    my $self = shift;

    my $sprite = P6Project::SpriteMaker->new->spritify(
        catdir($self->output_dir, qw/public content-pics spritable logos/),
        [qw/camelia-logo.png/],
    )->css;

    spurt $sprite => catfile $self->output_dir,
        qw/public sass sprite.css/;

    $self;
}

sub write_dist_db {
    my $self = shift;

    { # let model go out of scope, so the db file gets finished off
        unlink DB_FILE;
        my $m = ModulesPerl6::Model::Dists->new( db_file => DB_FILE )->deploy;
        $m->add(
            map +{
                name         => $_->{name},
                url          => $_->{url},
                description  => $_->{description},
                author_id    => $_->{auth},
                logo         => $_->{logo_sprite},
                has_readme   => $_->{badge_has_readme} ? 1 : 0,
                panda        => $_->{badge_panda}
                                    ? 2 : $_->{badge_panda_nos11} ? 1 : 0,
                has_tests    => $_->{badge_has_tests},
                travis_status=> $_->{travis_status},
                stars        => $_->{stargazers},
                issues       => $_->{open_issues},
                date_updated => eval {
                        Time::Moment->from_string($_->{last_updated_full})
                            ->epoch
                    } // 0,
                date_added   => Time::Moment->now->epoch,
                # TODO: fix to proper date_added date
            }, sort_by { $_->{name} } values %{ $self->projects }
        );
    }

    ModulesPerl6::Model::BuildStats->new( db_file => DB_FILE )->deploy->update(
        dists_num    => scalar(keys %{ $self->projects }),
        last_updated => time(),
    );

    move DB_FILE, catfile $self->output_dir, '..', 'mojo-app', DB_FILE;
    unless ( $self->no_app_start ) {
        system hypnotoad => catfile $self->output_dir,
            qw/.. mojo-app bin ModulesPerl6.pl/;
    }

    $self;
}

sub projects_list_order {
  my $prj1 = $a;
  my $prj2 = $b;

  $prj1 =~ s{^perl6-}{}i;
  $prj2 =~ s{^perl6-}{}i;

  return lc($prj1) cmp lc($prj2);
}


1;
