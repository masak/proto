#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use LWP::Simple;
use JSON;
use YAML qw (Load LoadFile);
use HTML::Template;

my $output_dir = shift(@ARGV) || './';
my @MEDALS = qw<fresh medal readme tests unachieved>;
binmode STDOUT, ':encoding(UTF-8)';

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
		
		my $repository = decode_json $project_page;
		$project ->{description}= $repository->{repository}->{description};
		
		my $commits = decode_json get("http://github.com/api/v2/json/commits/list/$project->{owner}/$project->{name}/master");
		my $latest = $commits->{commits}->[0];
		$project ->{last_updated}= $latest->{committed_date};
		my $tree = decode_json get("http://github.com/api/v2/json/tree/show/$project->{owner}/$project->{name}/$latest->{id}");
		my %files =  map { $_->{name} , $_->{type} } @{ $tree->{tree} };
		
		#try to get the logo if any
		if ( -e "$output_dir/logos" && $files{logotype} ) {
			my $logo_url = "http://github.com/$project->{owner}/$project->{name}/raw/master/logotype/logo_32x32.png";
			if ( head($logo_url) ) { 
				my $logo_name = $project->{name};
				$logo_name =~ s/\W+/_/;
				getstore ($logo_url , "$output_dir/logos/$logo_name.png") ; #TODO: unless filesize is same as the one we already have 
				$project ->{logo} = "./logos/$logo_name.png";
			}
		}
		
		$project ->{badge_has_tests} = $files{t} || $files{test} || $files{tests} ;
		$project ->{badge_has_readme} = $files{README} ? "http://github.com/$project->{owner}/$project->{name}/blob/master/README" : undef;
		$project ->{badge_is_popular} = $repository->{repository}->{watchers} && $repository->{repository}->{watchers} > 50;
		my ($yyy,$mm,$dd)= (localtime (time - (90*3600*24) ))[5,4,3,] ;  $yyy+=1900;$mm++; #There must be a better way to get yymmdd for 90 days ago
		$project ->{badge_is_fresh} = $project ->{last_updated} && $project->{last_updated} ge sprintf ("%04d-%02d-%02d" ,$yyy,$mm,$dd); #fresh is newer than 30 days ago
		sleep(3) ; #We are allowed 60 calls/min = 1 api call per second, and we are wasting 3 per request so we sleep for 3 secs to make up
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

system("mkdir $output_dir/logos") unless -e "$output_dir/logos" ;

my $projects = get_projects($list_url);

print "ok - $stats->{success}\nnok - $stats->{failed}\n";
print STDERR join '', @{ $stats->{errors} } if $stats->{errors};

die "Too many errors no output generated"
  if $stats->{failed} > $stats->{success};

unless ($output_dir eq './') {
    system("cp $_.png $output_dir") for @MEDALS;
}
spew( $output_dir . 'index.html', get_html_list($projects) );
spew( $output_dir . 'proto.json', get_json($projects) );

print "index.html and proto.json files generated\n";

sub spew {
    open( my $fh, ">:encoding(UTF-8)", shift ) or return -1;
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
