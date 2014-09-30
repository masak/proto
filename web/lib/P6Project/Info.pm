package P6Project::Info;

use strict;
use warnings;
use 5.010;

use JSON;
use File::Slurp;
use P6Project::Hosts::Github;
## TODO: add Gitorious support.

sub new {
    my ($class, %opts) = @_;
    my $self  = \%opts;
    return bless $self, $class;
}

sub p6p {
    my ($self) = @_;
    return $self->{p6p};
}

sub get_projects {
    my ($self, $list_url) = @_;
    my $ua = $self->p6p->ua;
    my $stats = $self->p6p->stats;
    my $projects = {};
    my $contents = eval { read_file('META.list.local') } || $ua->get($list_url)->res->body;
    my $hosts = {
        'github' => P6Project::Hosts::Github->new(p6p=>$self->p6p)
    };
    for my $proj (split "\n", $contents) {
        print "$proj\n";
        my $json = $ua->get($proj)->res->json;
        if (!$json) {
            $stats->error("Invalid json found at: $proj");
            next;
        }
        my $name = $json->{'name'};
        unless (defined $name) {
            warn "$proj has no name, skipping!\n";
            next;
        }
        my $url  = $json->{'source-url'} // $json->{'repo-url'};
        $projects->{$name}->{'url'} = $url;
        $projects->{$name}{success} = 0;
        my ($home) = $url =~ m[git://([\w\.]+)/];
        if ($home) {
            given ($home) {
                when (/github/) {
                    $projects->{$name}->{'home'} = 'github';
                    my ($auth, $repo_name) = $url =~ m[git://$home/([^/]+)/([^/]+)\.git];
                    $projects->{$name}->{'auth'} = $auth;
                    $projects->{$name}->{'repo_name'} = $repo_name;
                }
                default {
                    $stats->error("Unsupported repo host: $home");
                    next;
                }
            }
        }
        else {
            $stats->error("Invalid source-url found: $url");
            next;
        }
        $projects->{$name}->{'badge_panda'} = defined $json->{'source-url'};
        $projects->{$name}->{'badge_panda_nos11'} = defined $json->{'source-url'} && !defined $json->{'provides'};
        $projects->{$name}->{'description'} = $json->{'description'};
    }

    my $cached_projects = eval { 
        decode_json(read_file($self->p6p->output_dir . 'proto.json', binmode => ':encoding(UTF-8)'))
    };

    foreach my $project_name (keys %$projects) {
        my $project = $projects->{$project_name};
        $project->{name} = $project_name;
        print $stats->{success} . " $project_name\n";
        if (!$project->{home}) {
            delete $projects->{$project_name};
            next;
        }
        my $home = $hosts->{$project->{home}};
        if (!$home) {
            $stats->error("Could not handle specified host");
            next;
        }
        if ($home->set_project_info($project, $cached_projects->{$project_name})) {
            $stats->succeed;
        }
        print $project->{description}, "\n\n";
    }
    return $projects;
}

1;
