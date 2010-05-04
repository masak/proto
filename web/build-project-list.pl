#!/usr/bin/perl
use strict; use warnings;
use Data::Dumper;
use LWP::Simple;
use JSON ;
use YAML qw (Load LoadFile);

my $output_dir = shift(@ARGV) || './';

local $|=1;

my $list_url = 'http://github.com/masak/proto/raw/master/projects.list';

my $site_info = {
	'github' => {
			url=> sub { my $project = shift; "http://github.com/$project->{owner}/$project->{name}/"} ,
			get_description => qr/id="repository_description" rel="repository_description_edit">(.*)<span id="read_more"/s ,
		} ,
	'gitorious' => {
			url=> sub { my $project = shift; "http://gitorious.org/$project->{name}/"} ,
			get_description => qr/<div id="project-description" class="page">(.*?)<\/div>/s ,
		} ,
};

sub spew { 	open( my $fh, ">" ,shift ) or return -1;	print $fh @_ ; close $fh;return;} 	#spew ($filename,$data) ... saves $data in $filename.

sub get_projects {
	my ($list_url) = @_;
	my $projects = Load(get($list_url));
	foreach my $project_name (keys %$projects) {
		my $project = $projects->{$project_name};
		$project->{name} = $project_name;
		print "$project_name\n";
		next unless ($project->{home}) ;

		my $home = $site_info->{  $project->{home} };
		if (!$home) {
			print STDERR "Don't know how toget info for $project->{name} from $project->{home}\n";
			next;
		}

		$project->{url} = $home->{url}->($project) ;

		my $project_page = get ($project->{url});
		if (!$project_page) {
			print STDERR "Error for project $project->{name} : $project->{url}\n";
			next;
		}

		#Please forgive me for parsing html this way
		my ($desc) = $project_page =~ $home->{get_description} ;
		$desc =~ s/^\s+//;$desc =~ s/\s+$//; #trim spaces
		$desc =~ s/^<p>//;$desc =~ s/<\/p>//; #Remove the p tag
		$project->{description} = $desc ||'no description';
		print "$project->{description}\n\n" if $project->{description};

	}
	return $projects;
}

sub get_html_list {
	my ($projects) = @_;
	my $li ;
	foreach (sort keys %$projects) {
		my $project = $projects->{$_};
		if ($project->{description}) {
			$li .= qq(<li><a href="$project->{url}">$project->{name}</a>: $project->{description}</li>\n);
		}
	}
	return "<!DOCTYPE HTML><html><head><title>Proto List</title></head><body><ul>\n"
			.$li
			.'</ul></body>';
}

sub get_json {
	my ($projects) = @_;
	my $json = encode_json ($projects );
	#$json =~ s/},/},\n/g;
	return $json;
}

my $projects = get_projects($list_url);
spew ($output_dir . 'index.html'  ,get_html_list( $projects ) );
spew ($output_dir . 'proto.json'  ,get_json( $projects ) );

