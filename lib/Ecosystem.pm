class Ecosystem;

has $cache-dir;
has %!project-info;
has %!project-state;

method new(:$cache-dir!) {
    self.bless(
        self.CREATE(),
        cache-dir  => $cache-dir,
        project-info  => load-project-list('projects.list'),
        project-state => load-project-list('projects.state'),
    );
}

method contains-project($project) {
    # RAKUDO: :exists [perl #59794]
    return %!project-info.exists($project);
}

method get-info-on($project) {
    return %!project-info{$project};
}

method get-state($project) {
    if %!project-state.exists($project) {
        return %!project-state{$project}<state>;
    }
    if "$cache-dir/$project" ~~ :d {
        return 'fetched'
    }
    return 'not-here';
}

method set-state($project,$state) {
    %!project-state{$project} = {} unless %!project-state.exists($project);
    %!project-state{$project}<state> = $state;
    save-project-list('projects.state', %!project-state);
}

method regular-projects() {
    return %!project-info.keys.grep:
        { !%!project-info{$_}.exists('type')
          || !(%!project-info{$_}<type> eq 'pseudo'|'bootstrap') };
}

method project-dir($project) {
    return $cache-dir ~ ( %!project-info{$project}.exists('main_subdir')
                          ?? "/$project/{%!project-info{$project}<main_subdir>}"
                          !! "/$project"
                        );
}

method files-in-cache-lib($project) {
    my $project-dir = self.project-dir($project);
    my @cache_files = qqx{find $project-dir/lib/ -type f}\
                      .split(/\n+/)\
                      .grep({ $_ ne "" })\
                      .map: { $_.subst("$project-dir/lib/",'') };
    return @cache_files;
}

method fetched-projects() {
    return self.regular-projects.grep: { "$cache-dir/$_" ~~ :d };
}

method unfetched-projects() {
    return self.regular-projects.grep: { "$cache-dir/$_" !~~ :d };
}

sub load-project-list(Str $filename) {
    my $fh = open($filename)
        or die "Can't open '$filename': $!";

    my %overall;
    my $current-name;
    my %current;
    for $fh.lines {
        when / ^ <.ws> ['#' | $ ] /   { next };
        when / ^ (\S+) \: <.ws> ['#' | $ ] / {
            if $current-name.defined {
                %overall{$current-name} = %current.clone;
            }
            %current = ();
            $current-name = ~$0;
        }
        when / ^ <.ws> (\S+) ':' <.ws> (\S+) <.ws> ['#' | $ ] / {
            %current{~$0} = ~$1;
        }
        default {
            warn "don't know how to parse the line «$_», ignoring it"
        }
    }
    if %current {
        %overall{$current-name} = %current;
    }

    return %overall;
}

sub save-project-list(Str $filename, %overall) {
    my $fh = open( $filename, :w );
    for %overall.keys.sort -> $projectname {
        $fh.say("$projectname:");
        for %overall{$projectname}.keys.sort -> $key {
            $fh.say("    $key: {%overall{$projectname}{$key}}");
        }
        $fh.say("");
    }
    close $fh;
}

# vim: ft=perl6
