use v6;
use Test;

use App::Pls;

my %projects =
    will-succeed => {},
    will-fail    => {},
    # RAKUDO: Need quotes around keys starting with 'has-' [perl #75694]
    'has-deps'   => { :deps<A B> },
    A            => {},
    B            => { :deps<C D> },
    C            => {},
    D            => {},
    circ-deps    => { :deps<E> },
    E            => { :deps<circ-deps> },
    dirdep-fails => { :deps<will-fail> },
    indir-fails  => { :deps<dirdep-fails> },
;

class Mock::Fetcher does App::Pls::Fetcher {
}

my $core = App::Pls::Core.new(
    :projects(App::Pls::ProjectsState::Hash.new(%projects)),
    :fetcher(Mock::Fetcher.new()),
);

plan 24;

given $core {
    # [T] Fetch a project: Succeed.
    is .state-of(<will-succeed>), gone, "State is now 'gone'";
    is .fetch(<will-succeed>), success, "Fetch a project: Succeed";
    is .state-of(<will-succeed>), fetched, "State after: 'fetched'";

    # [T] Fetch a project; an unexpected error occurs: Fail.
    is .fetch(<will-fail>), failure, "Fetch a project: Fail";
    is .state-of(<will-fail>), gone, "State after: 'gone'";

    # [T] Fetch a project with dependencies: Fetch dependencies too.
    for <A B C D> -> $dep {
        is .state-of($dep), gone, "State before of $dep: 'gone'";
    }
    is .fetch(<has-deps>), success, "Fetch project's dependencies, too";
    for <A B C D> -> $dep {
        is .state-of($dep), fetched, "State after of $dep: 'fetched'";
    }

    # [T] Fetch a project with circular dependencies: Fail.
    is .fetch(<circ-deps>), failure, "Fetch a project with circ deps: fail";
    is .state-of(<circ-deps>), gone, "State after of circ-deps: 'gone'";
    is .state-of(<E>), gone, "State after of E: 'gone'";

    # [T] Fetch a project whose direct dependency fails: Fail.
    is .fetch(<dirdep-fails>), failure, "Fail on direct dependency failure";
    is .state-of(<dirdep-fails>), gone, "State after of dirdep-fails: 'gone'";
    is .state-of(<will-fail>), gone, "State after of will-fail: 'gone'";

    # [T] Fetch a project whose indirect dependency fails: Fail.
    is .fetch(<indir-fails>), failure, "Fail on indirect dependency failure";
    is .state-of(<indir-fails>), gone, "State after of indir-fails: 'gone'";
    is .state-of(<dirdep-fails>), gone, "State after of dirdep-fails: 'gone'";
    is .state-of(<will-fail>), gone, "State after of will-fail: 'gone'";
}
