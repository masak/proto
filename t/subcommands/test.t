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
    method fetch($project --> Result) {
        push @actions, "fetch[$project<name>]";
        $project<name> eq "won't-fetch" ?? failure !! success;
    }
}

class Mock::Builder does App::Pls::Builder {
    method build($project --> Result) {
        push @actions, "build[$project<name>]";
        $project<name> ~~ /^won\'t\-build/ ?? failure !! success;
    }
}

class Mock::Tester does App::Pls::Tester {
    method test($project --> Result) {
        push @actions, "test[$project<name>]";
        $project<name> eq "won't-test" ?? failure !! success;
    }
}

class Mock::Installer does App::Pls::Installer {
    method install($project --> Result) {
        push @actions, "install[$project<name>]";
        success;
    }
}


my $core = App::Pls::Core.new(
    :projects(App::Pls::ProjectsState::Hash.new(:%projects)),
    :ecosystem(App::Pls::Ecosystem::Hash.new(:%projects)),
    :fetcher(Mock::Fetcher.new()),
    :builder(Mock::Builder.new()),
    :tester(Mock::Tester.new()),
    :installer(Mock::Installer.new()),
);

plan 28;

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
    is .state-of("won't-fetch"), 'absent', "State after: unchanged";

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
        'fetch[C] test[A] install[A] build[C] test[C] install[C] build[D] '
        ~ 'test[D] install[D] build[B] test[B] install[B] test[has-deps]',
        "Fetch first, then build-test each project bottom-up";
    is .state-of("has-deps"), 'tested', "State after of has-deps: 'tested'";
    for <A B C D> -> $dep {
        is .state-of($dep), 'installed', "State after of $dep: 'installed'";
    }
}
