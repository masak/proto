#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use LWP::Simple;
use JSON;
use YAML qw (Load LoadFile);
use HTML::Template;

my $output_dir = shift(@ARGV) || './';

local $| = 1;
my $stats = { success => 0, failed => 0, errors => [] };

my $list_url = 'http://github.com/masak/proto/raw/master/projects.list';

my $site_info = {
    'github' => {
        set_project_info => sub {
		my $project = shift;
		$project ->{url}= "http://github.com/$project->{owner}/$project->{name}/";
		my $project_page = get ("http://github.com/api/v2/json/repos/show/$project->{owner}/$project->{name}");
		if ( !$project_page ) {
			return "Error for project $project->{name} : could not get $project->{url} (project probably dead)\n";
		}
		
		my $info = decode_json $project_page;
		$project ->{description}= $info->{repository}->{description};
		sleep(1) ; #We are allowed 60 calls/min = 1 api call per second
		return;
	}
    },
    'gitorious' => {
        set_project_info => sub {
		my $project = shift;
		$project ->{url}= "http://gitorious.org/$project->{name}/";

		my $project_page = get( $project->{url} );
		if ( !$project_page ) {
			return "Error for project $project->{name} : could not get $project->{url} (project probably dead)\n";
		}

		#Please forgive me for parsing html this way
		my ($desc) = $project_page =~ qr[<div id="project-description" class="page">\s*<p>(.*?)</p>\s*</div>]s;
		if (!$desc) {
			return "Could not get a description for $project->{name} from $project->{url}, that's BAD!\n";
		}
		$project->{description} = $desc;
		return ;
	},
    },
};

my $projects = get_projects($list_url);

print "ok - $stats->{success}\nnok - $stats->{failed}\n";
print STDERR join '', @{ $stats->{errors} } if $stats->{errors};

die "Too many errors no output generated"
  if $stats->{failed} > $stats->{success};

spew( $output_dir . 'index.html', get_html_list($projects) );
spew( $output_dir . 'proto.json', get_json($projects) );

print "index.html and proto.json files generated\n";

sub spew {
    open( my $fh, ">", shift ) or return -1;
    print $fh @_;
    close $fh;
    return;
}    #spew ($filename,$data) ... saves $data in $filename.

sub get_projects {
    my ($list_url) = @_;
    my $projects = eval { LoadFile('projects.list.local') } || Load( get($list_url) );

    foreach my $project_name ( keys %$projects ) {
        my $project = $projects->{$project_name};
        $project->{name} = $project_name;
	
        print "$stats->{success} $project_name\n";
        if ( !$project->{home} ) {
            delete $projects->{$project_name};
            next;
        }
	my $error;
        my $home = $site_info->{ $project->{home} };
        if ( !$home ) {
		$error = "Don't know how to get info for $project->{name} from $project->{home} (new repository?) \n";
        }

        $error ||= $home->{set_project_info}->($project);
        if ($error) {
		$stats->{failed}++;
		push @{ $stats->{errors} }, $error ;
		delete $projects->{$project_name};
        } else {
		$stats->{success}++;
	}
        print $project->{description}||$error,"\n\n";

    }
    return $projects;
}

sub get_html_list {
    my ($projects) = @_;
    my $li;
    my $template = HTML::Template->new(
        filename          => 'index.tmpl',
        die_on_bad_params => 0,
        default_escape    => 'html',
    );

    my @projects = map { $projects->{$_} }
      sort { lc($a) cmp lc($b) } keys %$projects;
    $template->param( projects => \@projects );
    return $template->output;
}

sub get_json {
    my ($projects) = @_;
    my $json = encode_json($projects);

    #$json =~ s/},/},\n/g;
    return $json;
}
