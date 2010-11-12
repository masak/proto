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
    method fetch($project --> Result) {
        $project<name> eq 'will-fail' ?? failure !! success;
    }
}

my $core = App::Pls::Core.new(
    :projects(App::Pls::ProjectsState::Hash.new(:%projects)),
    :ecosystem(App::Pls::Ecosystem::Hash.new(:%projects)),
    :fetcher(Mock::Fetcher.new()),
);

plan 14;

given $core {
    # [T] Fetch a project: Succeed.
    is .state-of('will-succeed'), 'absent', "State is now 'absent'";
    is .fetch(<will-succeed>), success, "Fetch a project: Succeed";
    is .state-of('will-succeed'), 'fetched', "State after: 'fetched'";

    # [T] Fetch a project; an unexpected error occurs: Fail.
    is .fetch(<will-fail>), failure, "Fetch a project: Fail";
    is .state-of('will-fail'), 'absent', "State after: 'absent'";

    # [T] Fetch a project with dependencies: don't fetch dependencies too.
    for <A B C D> -> $dep {
        is .state-of($dep), 'absent', "State before of $dep: 'absent'";
    }
    is .fetch(<has-deps>), success, "Fetch project's dependencies, too";
    for <A B C D> -> $dep {
        is .state-of($dep), 'absent', "State after of $dep: 'fetched'";
    }
}
