use v6;

subset State of Str where
    'absent' | 'fetched' | 'built' | 'tested' | 'installed'
;
enum Result <failure success forced-success>;

role App::Pls::ProjectsState {
    method state-of($project --> State) { !!! }
    method set-state-of($project, State $state) { !!! }
    method deps-of($project) { !!! }
    method reached-state($project, State $state --> Bool) { !!! }
}

class App::Pls::ProjectsState::Hash does App::Pls::ProjectsState {
    has %!projects;

    method new(%projects is rw) {
        self.bless(*, :%projects);
    }

    method state-of($project --> State) {
        die "No such project: $project"
            unless %!projects.exists($project);
        return %!projects{$project}<state> //= 'absent';
    }

    method set-state-of($project, State $state) {
        die "No such project: $project"
            unless %!projects.exists($project);
        %!projects{$project}<state> = $state;
    }

    method deps-of($project) {
        die "No such project: $project"
            unless %!projects.exists($project);
        if %!projects{$project}.exists('deps') {
            return %!projects{$project}<deps>.list;
        }
        return ();
    }

    method reached-state($project, $goal-state --> Bool) {
        my $actual-state = self.state-of($project);
        my @states = <absent fetched built tested installed>;
        my %state-levels = invert @states;
        return %state-levels{$actual-state} >= %state-levels{$goal-state};
    }
}

subset Project of Hash;

role App::Pls::Ecosystem {
    method project-info(Str $project --> Project) { !!! }
}

class App::Pls::Ecosystem::Hash {
    has %!projects;

    method new(%projects is rw) {
        self.bless(*, :%projects);
    }

    method project-info(Str $project --> Project) {
        die "No such project: $project"
            unless %!projects.exists($project);
        return { name => $project };
    }
}

role App::Pls::Fetcher {
    method fetch(Project $project) { !!! }
}

role App::Pls::Builder {
    method build(Project $project) { !!! }
}

role App::Pls::Tester {
    method test(Project $project) { !!! }
}

role App::Pls::Installer {
    method install(Project $project) { !!! }
}

class App::Pls::Core {
    # RAKUDO: Using 'handles' introduces a strange parameter-counting bug.
    #         [perl #75966]
    has App::Pls::ProjectsState $!projects; #   handles <state-of>;
    has App::Pls::Ecosystem     $!ecosystem;
    has App::Pls::Fetcher       $!fetcher;
    has App::Pls::Builder       $!builder;
    has App::Pls::Tester        $!tester;
    has App::Pls::Installer     $!installer;

    # RAKUDO: The 'handles' trait above should be enough.
    method state-of($project) {
        return $!projects.state-of($project);
    }

    method fetch(*@projects --> Result) {
        for @projects -> $project {
            my %*seen-projects;
            return failure
                if self!fetch-helper($project) == failure;
        }
        return success;
    }

    method !fetch-helper($project --> Result) {
        %*seen-projects{$project}++;
        for $!projects.deps-of($project) -> $dep {
            return failure
                if %*seen-projects{$dep};
            return failure
                if self!fetch-helper($dep) == failure;
        }
        if $!projects.reached-state($project, 'fetched') {
            return success;
        }
        elsif $!fetcher.fetch($!ecosystem.project-info($project)) != failure {
            $!projects.set-state-of($project, 'fetched');
            return success;
        }
        else {
            return failure;
        }
    }

    method build(*@projects) {
        for @projects -> $project {
            my %*seen-projects;
            return failure
                if self!fetch-helper($project) == failure;
            return failure
                if self!build-helper($project) == failure;
        }
        return success;
    }

    method !build-helper($project --> Result) {
        for $!projects.deps-of($project) -> $dep {
            return failure
                if self!build-helper($dep) == failure;
        }
        if $!projects.reached-state($project, 'built') {
            return success;
        }
        elsif $!builder.build($!ecosystem.project-info($project)) != failure {
            $!projects.set-state-of($project, 'built');
            return success;
        }
        else {
            return failure;
        }
    }

    method test(*@projects, Bool :$ignore-deps) {
        for @projects -> $project {
            my %*seen-projects;
            return failure
                if self!fetch-helper($project) == failure;
            return failure
                if self!build-helper($project) == failure;
            # RAKUDO: an unspecified $ignore-deps should be False, is Any
            return failure
                if self!test-helper($project, :ignore-deps(?$ignore-deps))
                    == failure;
        }
        return success;
    }

    method !test-helper($project, Bool :$ignore-deps --> Result) {
        unless $ignore-deps {
            for $!projects.deps-of($project) -> $dep {
                return failure
                    if self!test-helper($dep) == failure;
            }
        }
        if $!projects.reached-state($project, 'tested') {
            return success;
        }
        elsif $!tester.test($!ecosystem.project-info($project)) != failure {
            $!projects.set-state-of($project, 'tested');
            return success;
        }
        else {
            return failure;
        }
    }

    method install(*@projects, Bool :$force, Bool :$skip-test) {
        my $*needed-force = False;
        for @projects -> $project {
            my %*seen-projects;
            return failure
                if self!fetch-helper($project) == failure;
            return failure
                if self!build-helper($project) == failure;
            unless $skip-test {
                if self!test-helper($project) == failure {
                    return failure
                        unless $force;
                    $*needed-force = True;
                }
            }
            # RAKUDO: an unspecified $force should be False, is Any
            return failure
                if self!install-helper($project, :force(?$force)) == failure;
        }
        return $*needed-force ?? forced-success !! success;
    }

    method !install-helper($project, Bool :$force --> Result) {
        for $!projects.deps-of($project) -> $dep {
            # RAKUDO: an unspecified $force should be False, is Any
            if self!install-helper($dep, :force(?$force)) == failure {
                return failure
                    unless $force;
                $*needed-force = True;
            }
        }
        if $!projects.reached-state($project, 'installed') {
            return success;
        }
        elsif $!installer.install($!ecosystem.project-info($project))
                != failure {
            $!projects.set-state-of($project, 'installed');
            return success;
        }
        else {
            return failure;
        }
    }
}
