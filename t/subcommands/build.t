use v6;
use Test;

use App::Pls;

my %projects =
    fetched       => { :state<fetched> },
    unfetched     => {},
    "won't-fetch" => {},
    "won't-build" => {},
    # RAKUDO: Need quotes around keys starting with 'has-' [perl #75694]
    'has-deps'   => { :state<fetched>, :deps<A B> },
    A            => { :state<fetched> },
    B            => { :state<fetched>, :deps<C D> },
    C            => {},
    D            => { :state<built> },
    circ-deps    => { :state<fetched>, :deps<E> },
    E            => { :state<fetched>, :deps<circ-deps> },
    dirdep-fails => { :state<fetched>, :deps<won't-build> }, #'
    indir-fails  => { :state<fetched>, :deps<dirdep-fails> },
;

my @actions;

class Mock::Fetcher does App::Pls::Builder {
    method fetch($project --> Result) {
        push @actions, "fetch[$project]";
        $project eq "won't-fetch" ?? failure !! success;
    }
}

class Mock::Builder does App::Pls::Builder {
    method build($project --> Result) {
        push @actions, "build[$project]";
        $project eq "won't-build" ?? failure !! success;
    }
}

my $core = App::Pls::Core.new(
    :projects(App::Pls::ProjectsState::Hash.new(%projects)),
    :fetcher(Mock::Fetcher.new()),
    :builder(Mock::Builder.new()),
);

plan 31;

given $core {
    # [T] Build a project: Succeed.
    is .state-of('fetched'), 'fetched', "State before: 'fetched'";
    is .build(<fetched>), success, "Building project succeeded";
    is .state-of('fetched'), 'built', "State after: 'built'";

    # [T] Build an unfetched project: Fetch, build.
    @actions = ();
    is .state-of('unfetched'), 'absent', "State before: 'absent'";
    is .build(<unfetched>), success, "Building unfetched project succeeded";
    is ~@actions, 'fetch[unfetched] build[unfetched]',
        "Fetched the project before building it";
    is .state-of('unfetched'), 'built', "State after of unfetched: 'built'";

    # [T] Build an unfetched project; fetch fails. Fail.
    @actions = ();
    is .build(<won't-fetch>), failure, "Won't build if fetch fails"; # "
    is ~@actions, "fetch[won't-fetch]", "Didn't try building";
    is .state-of("won't-fetch"), 'absent',
        "State after of won't-fetch: unchanged";

    # [T] Build a project; a build error occurs: Fail.
    @actions = ();
    is .build(<won't-build>), failure, "Won't build if build fails"; # "
    is ~@actions, "fetch[won't-build] build[won't-build]", "Tried building";
    is .state-of("won't-build"), 'fetched',
        "State after of won't-build: 'fetched'";

    # [T] Build a project with dependencies: Build dependencies first.
    @actions = ();
    is .build(<has-deps>), success, "Building project with deps succeeds";
    is ~@actions, "fetch[C] build[A] build[C] build[B] build[has-deps]",
        "Fetch before build, build with postorder traversal";
    is .state-of('has-deps'), 'built', "State after of has-deps: built";
    for <A B C D> -> $dep {
        is .state-of($dep), 'built', "State after of $dep: built";
    }

    # [T] Build a project with circular dependencies: Fail.
    @actions = ();
    is .build(<circ-deps>), failure, "Building project with circ deps fails";
    is ~@actions, "", "Didn't even try to build anything";
    is .state-of('circ-deps'), 'fetched', "State after of circ-deps: unchanged";
    is .state-of('E'), 'fetched', "State after of E: unchanged";

    # [T] Build a project whose direct dependency fails: Fail.
    is .build(<dirdep-fails>), failure, "Fail when direct dep fails to build";
    is .state-of('dirdep-fails'), 'fetched',
        "State after of dirdep-fails: unchanged";
    is .state-of("won't-build"), 'fetched',
        "State after of won't-build: unchanged";

    # [T] Build a project whose indirect dependency fails: Fail.
    is .build(<indir-fails>), failure, "Fail when indirect dep fails to build";
    is .state-of('indir-fails'), 'fetched',
        "State after of indir-fails: unchanged";
    is .state-of('dirdep-fails'), 'fetched',
        "State after of dirdep-fails: unchanged";
    is .state-of("won't-build"), 'fetched',
        "State after of won't-build: unchanged";
}
