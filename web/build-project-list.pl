#!/usr/bin/perl
use strict;
use warnings;
use 5.010;

use Data::Dumper;
use LWP::Simple;
use JSON;
use YAML qw (Load LoadFile);
use HTML::Template;
use File::Slurp;
use Encode qw(encode_utf8);

my $output_dir = shift(@ARGV) || './';
my @MEDALS = qw<fresh medal readme tests unachieved proto camelia panda>;
binmode STDOUT, ':encoding(UTF-8)';

local $| = 1;
my $stats = { success => 0, failed => 0, errors => [] };

my $list_url = 'https://github.com/perl6/ecosystem/raw/master/META.list';

my $site_info = {
    'github' => {
        set_project_info => sub {
		my ($project , $previous )= @_;
        $project->{url} = "http://github.com/$project->{auth}/$project->{repo_name}/";
		if ( ! head( $project ->{url} ) ) {
			return "Error for project $project->{name} : could not get $project->{url} (project probably dead)\n";
		}

		my $commits = decode_json get("http://github.com/api/v2/json/commits/list/$project->{auth}/$project->{repo_name}/master");
		my $latest = $commits->{commits}->[0];
		$project ->{last_updated}= $latest->{committed_date};
		my ($yyy,$mm,$dd)= (localtime (time - (90*3600*24) ))[5,4,3,] ;  $yyy+=1900;$mm++; #There must be a better way to get yymmdd for 90 days ago
		$project ->{badge_is_fresh} = $project ->{last_updated} && $project->{last_updated} ge sprintf ("%04d-%02d-%02d" ,$yyy,$mm,$dd); #fresh is newer than 30 days ago
		
		if ( $previous && $previous->{last_updated} eq $latest->{committed_date} ) {
			$previous->{badge_is_fresh} = $project->{badge_is_fresh} ; #Even if the project was not modified we need to update this
            $previous->{badge_panda} = $project->{badge_panda};
			%$project = %$previous;
			print "Not updated since last check, loading from cache\n";
			sleep(1); #We only did one api call
			return;
		}
		print "Updated since last check\n";
		
		my $repository = decode_json get ("http://github.com/api/v2/json/repos/show/$project->{auth}/$project->{repo_name}");
		$project ->{description}= $repository->{repository}->{description};
		
		my $tree = decode_json get("http://github.com/api/v2/json/tree/show/$project->{auth}/$project->{repo_name}/$latest->{id}");
		my %files =  map { $_->{name} , $_->{type} } @{ $tree->{tree} };
		
		#try to get the logo if any
		if ( -e "$output_dir/logos" && $files{logotype} ) {
			my $logo_url = "http://github.com/$project->{auth}/$project->{repo_name}/raw/master/logotype/logo_32x32.png";
			if ( head($logo_url) ) { 
				my $logo_name = $project->{name};
				$logo_name =~ s/\W+/_/;
				getstore ($logo_url , "$output_dir/logos/$logo_name.png") ; #TODO: unless filesize is same as the one we already have 
				$project ->{logo} = "./logos/$logo_name.png";
			}
		}
		
		$project ->{badge_has_tests} = $files{t} || $files{test} || $files{tests} ;

        my @readmes = grep exists $files{$_}, qw/
                                                    README
                                                    README.pod
                                                    README.md
                                                    README.mkdn
                                                    README.mkd
                                                    README.markdown
                                                 /;

		$project ->{badge_has_readme} = scalar(@readmes) ? "http://github.com/$project->{auth}/$project->{repo_name}/blob/master/$readmes[0]" : undef;
		$project ->{badge_is_popular} = $repository->{repository}->{watchers} && $repository->{repository}->{watchers} > 50;
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
    system("cp fame-and-profit.html $output_dir");
}
write_file( $output_dir . 'index.html',{binmode => ':encoding(UTF-8)'}, encode_utf8(get_html_list($projects)) );
write_file( $output_dir . 'proto.json',{binmode => ':encoding(UTF-8)'}, get_json($projects) );

print "index.html and proto.json files generated\n";

sub get_projects {
    my ($list_url) = @_;
    my $projects;
    my $contents = eval { read_file('META.list.local') } || get($list_url);
    for my $proj (split "\n", $contents) {
        my $json = decode_json encode_utf8 get $proj;
        my $name = $json->{'name'};
        my $url = $json->{'source-url'} // $json->{'repo-url'};
        my ($auth, $repo_name)
            = $url =~ m[git://github.com/([^/]+)/([^.]+).git];
        $projects->{$name}->{'home'}      = "github";
        $projects->{$name}->{'auth'}      = $auth;
        $projects->{$name}->{'repo_name'} = $repo_name;
        $projects->{$name}->{'url'}  = $url;
        $projects->{$name}->{'badge_panda'} = defined $json->{'source-url'};
    }
    my $cached_projects = eval { decode_json read_file( $output_dir . 'proto.json' , binmode => ':encoding(UTF-8)' )  };

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

        $error ||= $home->{set_project_info}->($project , $cached_projects->{$project_name} );
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

    my @projects = keys %$projects;
    @projects = sort projects_list_order @projects;
    @projects = map { $projects->{$_} } @projects;

    $template->param( projects => \@projects );
    return $template->output;
}

sub get_json {
    my ($projects) = @_;
    my $json = encode_json($projects);

    #$json =~ s/},/},\n/g;
    return $json;
}

sub projects_list_order {
    my $prj1 = $a;
    my $prj2 = $b;

    # Disregard the [Pp]erl6-* prefix that some projects have
    $prj1 =~ s{^perl6-}{}i;
    $prj2 =~ s{^perl6-}{}i;

    return lc($prj1) cmp lc($prj2);
}

