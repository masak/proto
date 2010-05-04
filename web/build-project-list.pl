#!/usr/bin/perl
use strict; use warnings;
use Data::Dumper;
use LWP::Simple;
use JSON ;
use YAML qw (Load LoadFile);

my $output_dir = shift(@ARGV) || './';

local $|=1;
my $stats = {success=>0,failed=>0,errors=>[]};

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
			$stats->{failed}++;
			push @{ $stats->{errors} } , "Don't know how to get info for $project->{name} from $project->{home} (new repository?) \n";
			next;
		}

		$project->{url} = $home->{url}->($project) ;

		my $project_page = get ($project->{url});
		if (!$project_page) {
			$stats->{failed}++;
			push @{ $stats->{errors} } , "Error for project $project->{name} : could not get $project->{url} (project probably dead)\n";
			next;
		}

		#Please forgive me for parsing html this way
		my ($desc) = $project_page =~ $home->{get_description} ;
		$desc =~ s/^\s+//;$desc =~ s/\s+$//; #trim spaces
		$desc =~ s/^<p>//;$desc =~ s/<\/p>//; #Remove the p tag
		if ($desc) {
			$stats->{success}++;
			$project->{description} = $desc ;
		} else {
			$stats->{failed}++;
			push @{ $stats->{errors} } , "Could not get a description for $project->{name} from $project->{url}, that's BAD!\n";
			$project->{description} = '';
		}
		print "$project->{description}\n\n";

	}
	return $projects;
}

sub get_html_list {
	my ($projects) = @_;
	my $li ;
	foreach (sort { lc($a) cmp lc($b) } keys %$projects) {
		my $project = $projects->{$_};
		if ($project->{description}) {
			$li .= qq(<li><a href="$project->{url}">$project->{name}</a>: $project->{description}</li>\n);
		}
	}
	return '<!DOCTYPE HTML><html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"><title>Proto List</title></head><body><ul>'."\n"
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

print "ok - $stats->{success}\nnok - $stats->{failed}\n";
print STDERR join '', @{ $stats->{errors} }  if $stats->{errors};

die "Too many errors no output generated" if $stats->{failed} > $stats->{success};

spew ($output_dir . 'index.html'  ,get_html_list( $projects ) );
spew ($output_dir . 'proto.json'  ,get_json( $projects ) );

print "proto.html and proto.json files generated\n";