class Ecosystem:auth<masak>:ver<0.2.0>;
# The first proto series would have been version 0.0.x
# The installed-modules series would have been version 0.1.x
# Changed the :auth name-part when using git branch to fork the project.

has $cache-dir;
has %!project-info;
has %!project-state is rw;
has @.protected-files;

#--------------------------------- new ---------------------------------
method new(:$cache-dir!) {
    self.bless(
        self.CREATE(),
        cache-dir  => $cache-dir,
        project-info  => load-project-list('projects.list'),
        project-state => load-project-list('projects.state'),
        protected-files => <Configure.pm6 Configure.pir>,
#       protected-files => <Test.pm Test.pir Configure.pm Configure.pir>,
    );
}

#-------------------------- contains-project ---------------------------
method contains-project($project) {
    # RAKUDO: :exists [perl #59794]
    return %!project-info.exists($project);
}

#----------------------------- get-info-on -----------------------------
method get-info-on($project) {
    return %!project-info{$project};
}

#------------------------------ is-state -------------------------------
# The definition and implementation of project state is still in flux,
# particularly where one state overlaps with or implies another.
# For example, a test implies a successful build, but an installed
# project might have been cleaned from cache.
# Route all access to project state via the following methods
# (get-state, set-state and is-state) to shield the rest of the code
# as much as possible from changes to state definitions.
# The following states are currently in use (and may well change):
#   fetched    or  fetch-failed
#   built      or  build-failed
#   tested     or  test-failed
#   installed  or  install-failed
method is-state($project,$state) {
    if $state eq 'fetched' { return ?( "$cache-dir/$project" ~~ :d ); }
    if %!project-state.exists($project)
        and %!project-state{$project}.exists('state')
        and $state eq %!project-state{$project}<state> {
        return True;
    }
    return False;
}

#------------------------------ get-state ------------------------------
method get-state($project) {
    if %!project-state.exists($project) and %!project-state{$project}.exists('state') {
        return ~ %!project-state{$project}{'state'};
    }
    if self.is-state($project,'fetched') {
        return 'fetched'
    }
    return 'not-here';
}

#------------------------------ set-state ------------------------------
method set-state($project,$state) {
    unless %!project-state.exists($project) {
        %!project-state{$project} = {};
    }
    if $state {
        # WORKAROUND: you should not have to delete before updating
        %!project-state{$project}.delete('state');
        %!project-state{$project}<state> = $state;
    }
    else {
        %!project-state.delete($project); # because there was only <state>
    }
    save-project-list('projects.state', %!project-state);
}

#-------------------------- regular-projects ---------------------------
method regular-projects() {
    return %!project-info.keys.grep:
        { !%!project-info{$_}.exists('type')
          || !(%!project-info{$_}<type> eq 'pseudo'|'bootstrap') };
}

#----------------------------- project-dir -----------------------------
method project-dir($project) {
    my $dir = $cache-dir ~ "/$project";
    warn "PROJECT-DIR line 94 project=$project";
    if %!project-info{$project}.exists('main_subdir') {
        $dir ~= "/{%!project-info{$project}<main_subdir>}";
    }
    return $dir;
}

#------------------------- files-in-cache-lib --------------------------
method files-in-cache-lib($project) {
    my $project-dir = self.project-dir($project);
    
    if "$project-dir/lib" !~~ :d {
        return ();
    }

    my @cache_files = qqx{find $project-dir/lib/}\
                      .split(/\n+/)\
                      .map({$_.subst("$project-dir/lib/",'')})\
                      .grep({ $_ ne "" });
    return @cache_files;
}

#-------------------------- fetched-projects ---------------------------
method fetched-projects() {
    return self.regular-projects.grep: { "$cache-dir/$_" ~~ :d };
}

#------------------------- unfetched-projects --------------------------
method unfetched-projects() {
    return self.regular-projects.grep: { "$cache-dir/$_" !~~ :d };
}

#-------------------------- load-project-list --------------------------
sub load-project-list(Str $filename) {
    my $fh = open($filename)
        or die "Can't open '$filename': $!";

    my %overall;
    my $current-name;
    my %current;
    for $fh.lines {

        # ignore blank lines and comments
        when / ^ <.ws> ['#' | $ ] /   { next };
        # the [ '#' | $ ] may be a slighly evil, because the one option
        # is a literal character, and the other is an anchor. 

        # section name
        # WORKAROUND: Rakudo has a backtracking bug reported in
        # http://rt.perl.org/rt3/Public/Bug/Display.html?id=73608 and
        # http://nopaste.snit.ch/20018
#       when / ^ (\S+)     ':' <.ws> ['#' | $ ] / {
        when / ^ (<-[:]>+) ':' <.ws> ['#' | $ ] / {
            if $current-name.defined {
                %overall{$current-name} = %current.clone;
            }
            %current = ();
            $current-name = ~$0;
        }

        # key and value within section
        # WORKAROUND: Rakudo has a backtracking bug reported in
        # http://rt.perl.org/rt3/Public/Bug/Display.html?id=73608
#       when / ^ <.ws> (\S+)     ':' <.ws> (\S+) <.ws> ['#' | $ ] / {
        when / ^ <.ws> (<-[:]>+) ':' <.ws> (\S+) <.ws> ['#' | $ ] / {
            %current{~$0} = ~$1;
        }

        # oops - did not match any of the above
        default {
        # WORKAROUND: what happens to the embedded quotes?
        # Missing « or » at line 168, near " ignored b"
#           warn "warning: cannot parse «$_», ignored by Ecosystem.pm" ~
#                " load-project-list('$filename')";
            warn "warning: cannot parse '$_', ignored by Ecosystem.pm" ~
                 " load-project-list('$filename')";
        }
    }
    if %current {
        %overall{$current-name} = %current;
    }

    return %overall;
}

#-------------------------- save-project-list --------------------------
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
