use v6;
use Test;

use App::Pls;

my %projects =
    untested      => { :state<built> },
    unbuilt       => { :state<fetched> },
    unfetched     => {},
    "won't-test"  => { :state<built> },
    "won't-build" => { :state<fetched> },
    "won't-fetch" => {},
    "won't-build-2" => {},
    # RAKUDO: Need quotes around keys starting with 'has-' [perl #75694]
    'has-deps'    => { :state<built>, :deps<A B> },
    A             => { :state<built> },
    B             => { :state<fetched>, :deps<C D> },
    C             => {},
    D             => { :state<fetched> },
    ignore-deps   => { :state<built>, :deps<E F G> },
    E             => {},
    F             => { :state<fetched> },
    G             => { :state<built> },
;

my @actions;

class Mock::Fetcher does App::Pls::Fetcher {
    method fetch($project) {
        push @actions, "fetch[$project]";
        $project eq "won't-fetch" ?? failure !! success;
    }
}

class Mock::Builder does App::Pls::Builder {
    method build($project) {
        push @actions, "build[$project]";
        $project ~~ /^won\'t\-build/ ?? failure !! success;
    }
}

class Mock::Tester does App::Pls::Tester {
    method test($project) {
        push @actions, "test[$project]";
        $project eq "won't-test" ?? failure !! success;
    }
}

my $core = App::Pls::Core.new(
    :projects(App::Pls::ProjectsState::Hash.new(%projects)),
    :fetcher(Mock::Fetcher.new()),
    :builder(Mock::Builder.new()),
    :tester(Mock::Tester.new()),
);

plan 34;

given $core {
    # [T] Test a project: Succeed.
    is .state-of("untested"), 'built', "State before: 'built'";
    is .test(<untested>), success, "Testing the project succeeds";
    is .state-of("untested"), 'tested', "State after: 'tested'";

    # [T] Test an unbuilt project: Build, test.
    @actions = ();
    is .state-of("unbuilt"), 'fetched', "State before: 'fetched'";
    is .test(<unbuilt>), success, "Build and test succeeds";
    is ~@actions, 'build[unbuilt] test[unbuilt]', "Order is correct";
    is .state-of("unbuilt"), 'tested', "State after: 'tested'";

    # [T] Test an unbuilt project; build fails. Fail.
    @actions = ();
    is .test(<won't-build>), failure, "Won't build, and thus won't test"; #'
    is ~@actions, "build[won't-build]", "Tried building, not testing";
    is .state-of("won't-build"), 'fetched', "State after: unchanged";

    # [T] Test an unfetched project: Fetch, build, test.
    @actions = ();
    is .test(<unfetched>), success, "Fetch, build and test succeeds";
    is ~@actions, 'fetch[unfetched] build[unfetched] test[unfetched]',
        "Order is correct";
    is .state-of("unfetched"), 'tested', "State after: 'tested'";

    # [T] Test an unfetched project; fetch fails. Fail.
    @actions = ();
    is .test(<won't-fetch>), failure, "Won't fetch and thus won't test"; #'
    is ~@actions, "fetch[won't-fetch]",
        "Tried fetching, not building or testing";
    is .state-of("won't-fetch"), 'gone', "State after: unchanged";

    # [T] Test an unfetched project; build fails. Fail.
    @actions = ();
    is .test(<won't-build-2>), failure, "Won't build, and thus won't test"; #'
    is ~@actions, "fetch[won't-build-2] build[won't-build-2]",
        "Order is correct";
    is .state-of("won't-build-2"), 'fetched', "State after: 'fetched'";

    # [T] Test a project whose tests fail: Fail.
    is .test(<won't-test>), failure, "Won't test"; #"
    is .state-of("won't-test"), 'built', "State after: 'built'";

    # [T] Test a project with dependencies: fetch, build, test dependencies
    @actions = ();
    is .test(<has-deps>), success, "Test a project with dependencies";
    is ~@actions,
        'fetch[C] build[C] build[D] build[B] '
        ~ 'test[A] test[C] test[D] test[B] test[has-deps]',
        "Fetch first, then build (postorder), then test (postorder)";
    is .state-of("has-deps"), 'tested', "State after of has-deps: 'tested'";
    for <A B C D> -> $dep {
        is .state-of($dep), 'tested', "State after of $dep: 'tested'";
    }

    # [T] Test a projects with dependencies, but explicitly ignoring the
    #     dependencies: test only the project, do not fetch/build dependencies
    @actions = ();
    is .test(<ignore-deps>, :ignore-deps), success, "Test-ignore-deps works";
    is ~@actions, 'fetch[E] build[E] build[F] test[ignore-deps]',
        "Only ignore-deps is tested";
    is .state-of("ignore-deps"), 'tested', "State after: 'tested'";
    is .state-of("E"), 'built', "State after of E: 'built'";
    is .state-of("F"), 'built', "State after of F: 'built'";
    is .state-of("G"), 'built', "State after of G: unchanged";
}
