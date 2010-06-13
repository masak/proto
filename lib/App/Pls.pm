use v6;

subset State of Str where {
    'gone' | 'fetched' | 'built' | 'tested' | 'installed'
};
enum Result <failure success forced-success>;

role App::Pls::ProjectsState {
    method state-of($project --> State) { !!! }
    method set-state-of($project, State $state) { !!! }
    method deps-of($project) { !!! }
}

class App::Pls::ProjectsState::Hash does App::Pls::ProjectsState {
    has %!projects;

    method new(%projects is rw) {
        self.bless(*, :%projects);
    }

    method state-of($project --> State) {
        (%!projects{$project} // { :state<gone> })<state> // 'gone';
    }

    method set-state-of($project, State $state) {
        %!projects{$project}<state> = $state;
    }

    method deps-of($project) {
        if %!projects.exists($project) {
            if %!projects{$project}.exists('deps') {
                return %!projects{$project}<deps>.list;
            }
            return ();
        }
        die "No such project: $project";
    }
}

role App::Pls::Fetcher {
    method fetch($project) { !!! }
}

role App::Pls::Builder {
}

role App::Pls::Tester {
}

role App::Pls::Installer {
}

class App::Pls::Core {
    has App::Pls::ProjectsState $!projects;
    has App::Pls::Fetcher       $!fetcher;
    has App::Pls::Builder       $!builder;

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
        if $!fetcher.fetch($project) == success {
            $!projects.set-state-of($project, 'fetched');
            return success;
        }
        else {
            return failure;
        }
    }

    method build(*@projects) {
        return;
    }

    method test(*@projects, Bool :$ignore-deps) {
        return;
    }

    method install(*@projects, Bool :$force, Bool :$skip-test) {
        return;
    }
}
