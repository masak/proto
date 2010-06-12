use v6;

enum State <gone fetched built tested>;
enum Result <success failure>;

role App::Pls::ProjectsState {
}

class App::Pls::ProjectsState::Hash does App::Pls::ProjectsState {
}

role App::Pls::Fetcher {
}

role App::Pls::Builder {
}

role App::Pls::Tester {
}

class App::Pls::Core {
    has App::Pls::ProjectsState $!projects;
    has App::Pls::Fetcher       $!fetcher;
    has App::Pls::Builder       $!builder;

    method state-of($project) {
        return -1;
    }

    method fetch(*@projects) {
        return;
    }

    method build(*@projects) {
        return;
    }

    method test(*@projects, Bool :$ignore-deps) {
        return;
    }
}
