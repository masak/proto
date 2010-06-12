use v6;

enum State <gone fetched>;
enum Result <success failure>;

role App::Pls::ProjectsState {
}

class App::Pls::ProjectsState::Hash does App::Pls::ProjectsState {
}

role App::Pls::Fetcher {
}

class App::Pls::Core {
    has App::Pls::ProjectsState $!projects;
    has App::Pls::Fetcher       $!fetcher;

    method state-of($project) {
        return -1;
    }

    method fetch(*@projects) {
        return;
    }
}
