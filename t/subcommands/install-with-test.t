use v6;
use Test;

use App::Pls;

my %projects =
    uninstalled     => { :state<tested> },
    "won't-install" => { :state<tested> },
    untested        => { :state<built> },
    "won't-test"    => { :state<built> },
    unbuilt         => { :state<fetched> },
    "won't-build"   => { :state<fetched> },
    "won't-test-2"  => { :state<fetched> },
    unfetched       => {},
    "won't-fetch"   => {},
    "won't-build-2" => {},
    "won't-test-3"  => {},
    "has-deps"      => { :state<fetched>, :deps<A B> },
    A               => { :state<installed> },
    B               => { :state<built>, :deps<C D> },
    C               => {},
    D               => { :state<built> },
    "circ-deps"     => { :state<tested>, :deps<E> },
    E               => { :state<tested>, :deps<circ-deps> },
    "dirdep-fails"  => { :state<tested>, :deps<won't-install> }, #'
    "indir-fails"   => { :state<tested>, :deps<dirdep-fails> },
;

my @actions;

class Mock::Fetcher does App::Pls::Fetcher {
}

class Mock::Builder does App::Pls::Builder {
}

class Mock::Tester does App::Pls::Tester {
}

class Mock::Installer does App::Pls::Installer {
}

my $core = App::Pls::Core.new(
    :projects(App::Pls::ProjectsState::Hash.new(%projects)),
    :fetcher(Mock::Fetcher.new()),
    :builder(Mock::Builder.new()),
    :tester(Mock::Tester.new()),
    :installer(Mock::Installer.new()),
);

plan 51;

given $core {
    # [T] Install a tested project: Succeed.
    is .state-of("uninstalled"), 'tested', "State before: 'tested'";
    is .install(<uninstalled>), success, "Install of tested project succeeded";
    is .state-of("uninstalled"), 'installed', "State after: 'installed'";

    # [T] Install a tested project whose install fails: Fail.
    is .state-of("won't-install"), 'tested', "State before: 'tested'";
    is .install(<won't-install>), failure, "An install that fails"; #'
    is .state-of("won't-install"), 'tested', "State after: unchanged";

    # [T] Install an untested project: Test, install.
    @actions = ();
    is .state-of("untested"), 'built', "State before: 'built'";
    is .install(<untested>), success, "Test, then install succeeds.";
    is ~@actions, 'test[untested] install[untested]', "Correct order";
    is .state-of("untested"), 'installed', "State after: 'installed'";

    # [T] Install an untested project; testing fails. Fail.
    @actions = ();
    is .install(<won't-test>), failure, "Testing fails, won't install"; #"
    is ~@actions, "test[won't-test]", "Tested, didn't install";
    is .state-of("won't test"), 'built', "State after: unchanged";

    # [T] Install an unbuilt project: Build, test, install.
    @actions = ();
    is .install(<unbuilt>), success, "Build, test, install";
    is ~@actions, 'build[unbuilt] test[unbuilt] install[unbuilt]',
        "Order is correct";
    is .state-of("unbuilt"), 'installed', "State after: 'installed'";

    # [T] Install an unbuilt project; build fails. Fail.
    @actions = ();
    is .install(<won't-build>), failure, "Build fails, won't install"; #"
    is ~@actions, "build[won't-build]", "Didn't try to install";
    is .state-of("won't-build"), 'fetched', "State after: unchanged";

    # [T] Install an unbuilt project; testing fails. Fail.
    @actions = ();
    is .install(<won't-test-2>), failure, "Testing fails, won't install"; #"
    is ~@actions, "build[won't-test-2] test[won't-test-2]",
        "Built and tested, but didn't try to install";
    is .state-of("won't-test-2"), 'built', "State after: 'built'";

    # [T] Install an unfetched project: Fetch, build, test, install.
    @actions = ();
    is .install(<unfetched>), success, "Fetch, build, test, install";
    is ~@actions,
        'fetch[unfetched] build[unfetched] test[unfetched] install[unfected]',
        "Correct order";
    is .state-of("unfetched"), 'installed', "State after: 'installed'";

    # [T] Install an unfetched project; fetch fails. Fail.
    @actions = ();
    is .install(<won't-fetch>), failure, "Fetching fails, won't install"; #"
    is ~@actions, "fetch[won't-fetch]", "Tried to fetch, not build etc";
    is .state-of("won't-fetch"), 'gone', "State after: unchanged";

    # [T] Install an unfetched project; build fails. Fail.
    @actions = ();
    is .install(<won't-build-2>), failure, "Build fails, won't install"; #"
    is ~@actions, "fetch[won't-build-2] build[won't-build-2]",
        "Tried to fetch and build, not test etc";
    is .state-of("won't-build-2"), 'fetched', "State after: 'fetched'";

    # [T] Install an unfetched project; testing fails. Fail.
    @actions = ();
    is .install(<won't-test-3>), failure, "Test fails, won't install"; #"
    is ~@actions, "fetch[won't-test-3] build[won't-test-3] test[won't-test-3]",
        "Tried to fetch, build and test, not install";
    is .state-of("won't-test-3"), 'built', "State after: 'built'";

    # [T] Install a project with dependencies: Install dependencies too.
    @actions = ();
    is .install(<has-deps>), success, "Install a project with dependencies";
    is ~@actions, 'fetch[C] build[C] build[has-deps] '
                  ~ 'test[C] test[D] test[B] test[has-deps] '
                  ~ 'install[C] install[D] install[B] install[has-deps]',
        "fetch, build, test and install (all postorder and by need)";
    is .state-of("has-deps"), 'installed',
        "State after of has-deps: 'installed'";
    for <A B C D> -> $dep {
        is .state-of($dep), 'installed', "State after of $dep: 'installed'";
    }

    # [T] Install a project with circular dependencies: Fail.
    @actions = ();
    is .install(<circ-deps>), failure, "Circular dependency install: fail";
    is ~@actions, '', "Nothing was done";
    is .state-of("circ-deps"), 'tested', "State after of circ-deps: unchanged";
    is .state-of("E"), 'tested', "State after of E: unchanged";

    # [T] Install a project whose direct dependency fails: Fail.
    @actions = ();
    is .install(<dirdep-fails>), failure, "Direct dependency fails: fail";
    is ~@actions, "install[won't-install]", "Still, an install was attempted";
    is .state-of("won't-install"), 'tested', "State after: unchanged";

    # [T] Install a project whose indirect dependency fails: Fail.
    @actions = ();
    is .install(<indir-fails>), failure, "Indirect dependency fails: fail";
    is ~@actions, "install[won't-install]", "Still, an install was attempted";
    is .state-of("won't-install"), 'tested', "State after: unchanged";
}
