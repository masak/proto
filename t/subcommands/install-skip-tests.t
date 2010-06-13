use v6;
use Test;

use App::Pls;

my %projects =
    uninstalled     => { :state<built> },
    "won't-install" => { :state<built> },
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
    "circ-deps"     => { :state<built>, :deps<E> },
    E               => { :state<built>, :deps<circ-deps> },
    "dirdep-fails"  => { :state<built>, :deps<won't-install> }, #'
    "indir-fails"   => { :state<built>, :deps<F> },
    F               => { :state<built>, :deps<won't-install G H> }, #'
    G               => { :state<built> },
    H               => { :state<built> },
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

plan 41;

given $core {
    # [T] Install-ST a tested project: Succeed.
    is .install(<uninstalled>, :skip-test), success,
        "Install-skip-test on an already tested project";

    # [T] Install-ST an untested project: Don't test, install.
    @actions = ();
    is .install(<won't-test>, :skip-test), success, #'
        "Tests are never run, go directly to install";
    is ~@actions, "install[won't-test]", "Tests skipped, installed";
    is .state-of("won't test"), 'installed', "State after: 'installed'";

    # [T] Install-ST an unbuilt project: Build, don't test, install.
    @actions = ();
    is .install(<unbuilt>, :skip-test), success, "Build, skip test, install";
    is ~@actions, 'build[unbuilt] install[unbuilt]', "Didn't run the tests";
    is .state-of("unbuilt"), 'installed', "State after: 'installed'";

    # [T] Install-ST an unbuilt project; build fails. Fail.
    @actions = ();
    is .install(<won't-build>, :force), failure, #'
        "Build fails, won't install";
    is ~@actions, "build[won't-build]", "Didn't try to install";
    is .state-of("won't-build"), 'fetched', "State after: unchanged";

    # [T] Install-ST an unfetched project: Fetch, build, don't test, install.
    @actions = ();
    is .install(<unfetched>, :skip-test), success,
        "Fetch, build, skip test, install";
    is ~@actions, 'fetch[unfetched] build[unfetched] install[unfetched]',
        "Didn't run the tests";
    is .state-of("unfetched"), 'installed', "State after: 'installed'";

    # [T] Install-ST an unfetched project; fetch fails. Fail.
    @actions = ();
    is .install(<won't-fetch>, :skip-test), failure, #'
        "Fetching fails, won't install";
    is ~@actions, "fetch[won't-fetch]", "Tried to fetch, not build etc";
    is .state-of("won't-fetch"), 'gone', "State after: unchanged";

    # [T] Install-ST an unfetched project; build fails. Fail.
    @actions = ();
    is .install(<won't-build-2>, :skip-test), failure, #'
        "Build fails, won't install";
    is ~@actions, "fetch[won't-build-2] build[won't-build-2]",
        "Tried to fetch and build, not test etc";
    is .state-of("won't-build-2"), 'fetched', "State after: 'fetched'";

    # [T] Install-ST a project with dependencies: Install-ST dependencies too.
    @actions = ();
    is .install(<has-deps>, :skip-test), success,
        "Install a project with dependencies";
    is ~@actions, 'fetch[C] build[C] build[has-deps] '
                  ~ 'install[C] install[D] install[B] install[has-deps]',
        "fetch, build and install (all postorder and by need). no test.";
    is .state-of("has-deps"), 'installed',
        "State after of has-deps: 'installed'";
    for <A B C D> -> $dep {
        is .state-of($dep), 'installed', "State after of $dep: 'installed'";
    }

    # [T] Install-ST a project with circular dependencies: Fail.
    @actions = ();
    is .install(<circ-deps>, :skip-test), failure,
        "Circular dependency install: fail";
    is ~@actions, '', "Nothing was done";
    is .state-of("circ-deps"), 'tested', "State after of circ-deps: unchanged";
    is .state-of("E"), 'tested', "State after of E: unchanged";

    # [T] Install-ST a project whose direct dependency fails: Fail.
    @actions = ();
    is .install(<dirdep-fails>, :skip-test), failure,
        "Direct dependency fails: fail";
    is ~@actions, "install[won't-install]",
        "Install fails on first project, doesn't proceed";
    is .state-of("won't-install"), 'built',
        "State after of won't-install: unchanged";
    is .state-of("dirdep-fails"), 'built',
        "State after of dirdep-fails: unchanged";

    # [T] Install-ST a project whose indirect dependency fails: Fail.
    @actions = ();
    is .install(<indir-fails>, :skip-test), failure,
        "Indirect dependency fails: fail";
    is ~@actions, "install[won't-install]",
        "Installation fails on first project, doesn't proceed";
    is .state-of("won't-install"), 'built', "State after: unchanged";
    for <F G H> -> $dep {
        is .state-of($dep), 'built', "State after of $dep: unchanged";
    }
    is .state-of("indir-fails"), 'built',
        "State after of indir-fails: unchanged";
}
