use v6;
use Test;

use App::Pls;

my %projects =
    "won't-test"    => { :state<built> },
    "won't-build"   => { :state<fetched> },
    "won't-test-2"  => { :state<fetched> },
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
    "won't-install" => { :state<tested> },
    "indir-fails"   => { :state<tested>, :deps<F> },
    F               => { :state<tested>, :deps<won't-install G H> }, #'
    G               => { :state<tested> },
    H               => { :state<tested> },
;

my @actions;

class Mock::Fetcher does App::Pls::Fetcher {
    method fetch($project --> Result) {
        push @actions, "fetch[$project<name>]";
        return failure
            if $project<name> eq "won't-fetch";
        return success;
    }
}

class Mock::Builder does App::Pls::Builder {
    method build($project --> Result) {
        push @actions, "build[$project<name>]";
        return failure
            if $project<name> ~~ /^ won\'t\-build/;
        return success;
    }
}

class Mock::Tester does App::Pls::Tester {
    method test($project --> Result) {
        push @actions, "test[$project<name>]";
        return failure
            if $project<name> ~~ /^ won\'t\-test/;
        return success;
    }
}

class Mock::Installer does App::Pls::Installer {
    method install($project --> Result) {
        push @actions, "install[$project<name>]";
        return failure
            if $project<name> eq "won't-install";
        return success;
    }
}

my $core = App::Pls::Core.new(
    :projects(App::Pls::ProjectsState::Hash.new(%projects)),
    :ecosystem(App::Pls::Ecosystem::Hash.new(%projects)),
    :fetcher(Mock::Fetcher.new()),
    :builder(Mock::Builder.new()),
    :tester(Mock::Tester.new()),
    :installer(Mock::Installer.new()),
);

plan 40;

given $core {
    # [T] Force install an untested project; testing fails. Install anyway.
    @actions = ();
    is .install(<won't-test>, :force), forced-success, #'
        "Testing fails, install anyway";
    is ~@actions, "test[won't-test] install[won't-test]", "Tested, installed";
    is .state-of("won't-test"), 'installed', "State after: 'installed'";

    # [T] Force install an unbuilt project; build fails. Fail.
    @actions = ();
    is .install(<won't-build>, :force), failure, #'
        "Build fails, won't install";
    is ~@actions, "build[won't-build]", "Didn't try to install";
    is .state-of("won't-build"), 'fetched', "State after: unchanged";

    # [T] Force install an unbuilt project; testing fails. Install anyway.
    @actions = ();
    is .install(<won't-test-2>, :force), forced-success, #'
        "Testing fails, install anyway";
    is ~@actions, "build[won't-test-2] test[won't-test-2] "
                  ~ "install[won't-test-2]",
        "Built, tested and installed";
    is .state-of("won't-test-2"), 'installed', "State after: 'installed'";

    # [T] Force install an unfetched project; fetch fails. Fail.
    @actions = ();
    is .install(<won't-fetch>, :force), failure, #'
        "Fetching fails, won't install";
    is ~@actions, "fetch[won't-fetch]", "Tried to fetch, not build etc";
    is .state-of("won't-fetch"), 'absent', "State after: unchanged";

    # [T] Force install an unfetched project; build fails. Fail.
    @actions = ();
    is .install(<won't-build-2>, :force), failure, #'
        "Build fails, won't install";
    is ~@actions, "fetch[won't-build-2] build[won't-build-2]",
        "Tried to fetch and build, not test etc";
    is .state-of("won't-build-2"), 'fetched', "State after: 'fetched'";

    # [T] Force install an unfetched project; testing fails. Install anyway.
    @actions = ();
    is .install(<won't-test-3>, :force), forced-success, #'
        "Test fails, install anyway";
    is ~@actions, "fetch[won't-test-3] build[won't-test-3] test[won't-test-3] "
                  ~ "install[won't-test-3]",
        "Fetch, build, test and install";
    is .state-of("won't-test-3"), 'installed', "State after: 'installed'";

    # [T] Force install a project with dependencies: Install dependencies too.
    @actions = ();
    is .install(<has-deps>, :force), success,
        "Install a project with dependencies";
    is ~@actions, 'fetch[C] build[C] build[has-deps] '
                  ~ 'test[C] test[D] test[B] test[has-deps] '
                  ~ 'install[C] install[D] install[B] install[has-deps]',
        "fetch, build, test and install (all postorder and by need)";
    is .state-of("has-deps"), 'installed',
        "State after of has-deps: 'installed'";
    for <A B C D> -> $dep {
        is .state-of($dep), 'installed', "State after of $dep: 'installed'";
    }

    # [T] Force install a project with circular dependencies: Fail.
    @actions = ();
    is .install(<circ-deps>, :force), failure,
        "Circular dependency install: fail";
    is ~@actions, '', "Nothing was done";
    is .state-of("circ-deps"), 'tested', "State after of circ-deps: unchanged";
    is .state-of("E"), 'tested', "State after of E: unchanged";

    # [T] Froce install a project whose direct dependency fails:
    #     Install anyway.
    @actions = ();
    is .install(<dirdep-fails>, :force), forced-success,
        "Direct dependency fails but project itself succeds: succeed";
    is ~@actions, "install[won't-install] install[dirdep-fails]",
        "Install proceeds even after failure";
    is .state-of("won't-install"), 'tested',
        "State after of won't-install: unchanged";
    is .state-of("dirdep-fails"), 'installed',
        "State after of dirdep-fails: 'installed'";

    # [T] Force install a project whose indirect dependency fails:
    #     Install anyway.
    @actions = ();
    is .install(<indir-fails>, :force), forced-success,
        "Indirect dependency fails but project itself succeeds: succeed";
    is ~@actions, "install[won't-install] install[G] install[H] install[F] "
                  ~ "install[indir-fails]",
        "Installation of all projects are made, though the first fails";
    is .state-of("won't-install"), 'tested', "State after: unchanged";
    for <F G H> -> $dep {
        is .state-of($dep), 'installed', "State after of $dep: 'installed'";
    }
    is .state-of("indir-fails"), 'installed',
        "State after of indir-fails: 'installed'";
}
