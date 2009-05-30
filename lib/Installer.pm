use v6;
use Ecosystem;

class Installer {
    has %!config-info;
    has Ecosystem $.ecosystem;

    method new() {
        self.bless(
            # self.CREATE(), # un-comment for latest Rakudo
            config-info => (my $c = load-config-file('config.proto')),
            ecosystem   => Ecosystem.new($c{'Proto projects directory'}),
        )
    }

    # Returns a block which calls the right subcommand with a variable number
    # of parameters. If the provided subcommand is unknown or undef, this
    # method exits immediately.
    method subcommand-dispatch($command) {
        my @available-commands = <install update uninstall test showdeps>;
        given $command {
            when undef                    { exit }
            when any(@available-commands) {} # fall out, approved
            default {
                .say for
                    "Unrecognized subcommand '$command'. A typical usage is:",
                    q['./proto install <projectname>'],
                    'Available commands: ' ~ @available-commands,
                    'See the README for more details';
                exit;
            }
        };
        return eval sprintf '{ -> *@projects { self.%s( @projects) } }',
                            $command;
    }

    method install(*@projects) {
        my @projects-to-install;
        my $missing-projects = False;
        for @projects -> $project {
            if !$.ecosystem.contains-project($project) {
                say "Project not found: '$project'";
                $missing-projects = True;
            }
            elsif $project eq 'all' {
                @projects-to-install.push($.ecosystem.uninstalled-projects());
            }
            elsif "{%!config-info{'Proto projects directory'}}/$project"
                    ~~ :d {
                say "Won't install $project: already installed.";
            }
            else {
                @projects-to-install.push($project);
            }
        }
        if $missing-projects {
            say 'Try updating proto to get the latest list of projects.';
            exit(1);
        }
        if !@projects-to-install {
            say 'Nothing to install.';
            exit(1);
        }
        self.fetch-and-build-projects-and-their-deps(
            @projects-to-install.uniq
        );
    }

    method update(*@projects) {
        my @projects-to-update;
        my $missing-projects = False;
        for @projects -> $project {
            if !$.ecosystem.contains-project($project) {
                say "No such project: '$project'";
                $missing-projects = True;
            }
            elsif $project eq 'all' {
                @projects-to-update.push($.ecosystem.installed-projects());
            }
            elsif "{%!config-info{'Proto projects directory'}}/$project"
                    !~~ :d {
                say "Cannot update $project: not installed.";
            }
            else {
                @projects-to-update.push($project);
            }
        }
        if $missing-projects {
            exit(1);
        }
        if !@projects-to-update {
            say 'Nothing to update.';
            exit(1);
        }
        self.fetch-and-build-projects-and-their-deps(
            @projects-to-update.uniq
        );
    }

    method uninstall(*@projects) {
        for @projects -> $project {
            if !$.ecosystem.contains-project($project) {
                say "Project not found: '$project'";
                say "Aborting.";
            }
            elsif $project eq 'all' {
                say "'uninstall all' not implemented yet";
                # TODO: Implement.
            }
            elsif "{%!config-info{'Proto projects directory'}}/$project"
                    !~~ :d {
                say "Won't uninstall $project: not found.";
                say "Aborting.";
            }
        }
        for $.ecosystem.installed-projects() -> $project {
            next if $project eq any(@projects);
            for self.get-deps($project) -> $dep {
                if $dep eq any(@projects) {
                    say "Cannot uninstall $dep, depended on by $project.";
                    say "Aborting.";
                    return;
                }
            }
        }
        for @projects -> $project {
            print "Removing $project...";
            my $target-dir = %!config-info{'Proto projects directory'}
                             ~ "/$project";
            run("rm -rf $target-dir");
            say "done";
        }
    }

    method test(*@projects) {
        unless @projects {
            say 'You have to specify what you want to test.';
            # TODO: Maybe just test everything installed?
            exit 1;
        }
        my $can-continue = True;
        for @projects -> $project {
            unless $.ecosystem.contains-project($project) {
                say "Project not found: '$project'";
                $can-continue = False;
            }
            unless $.ecosystem.is-installed($project) {
                say "Project '$project' is not installed";
                $can-continue = False;
            }
        }
        unless $can-continue {
            say "Aborting...";
            exit(1);
        }
        for @projects -> $project {
            my %info = $.ecosystem.get-info-on($project);
            # RAKUDO: Doesn't support any other way to change the current
            #         working directory. Improvising.
            my $project-dir
                = %!config-info{'Proto projects directory'}
                    ~ ( %info.exists('main_subdir')
                        ?? "/$project/{%info<main_subdir>}"
                        !! "/$project"
                      );
            my $in-dir = "cd $project-dir";
            # RAKUDO: Can't really figure out how to set environment variables
            #         so they're visible by later commands. Doing like this
            #         instead.
            my $p6l = sprintf 'env PERL6LIB=%s:%s/lib',
                              %!config-info{'Proto projects directory'},
                              $project-dir;
            print "Testing $project... ";
            run( "$in-dir; $p6l make test" );
        }
    }

    # TODO: This sub should probably recursively show dependencies, and in
    #       such a way that a dependency found twice by different routes is
    #       only mentioned the second time -- its dependencies are not shown.
    method showdeps(*@projects) {
        unless @projects {
            say "You have to specify which projects' dependencies to show.";
            exit 1;
        }
        for @projects -> $project {
            if "{%!config-info{'Proto projects directory'}}/$project" !~~ :d {
                say "$project is not installed.";
                next;
            }
            if !self.get-deps($project) {
                say "$project has no dependencies.";
                next;
            }
            self.showdeps-recursively($project);
        }
    }

    # TODO: Detect circularity by replacing the $indent parameter with a
    #       list of ancestor projects, and checking against inclusion in
    #       that list.
    submethod showdeps-recursively(Str $project, Int $indent = 0) {
        say '  ' x $indent, $project, ':';
        for self.get-deps($project) -> $dep {
            if self.get-deps($dep) {
                self.showdeps-recursively($dep, int($indent + 1));
            }
            else {
                say '  ' x ($indent + 1), $dep;
            }
        }
    }

    submethod fetch-and-build-projects-and-their-deps(@projects) {
        # TODO: Though the below traversal works, it seems much cooler to do
        #       builds as soon as possible. Right now, in a dep tree looking
        #       like this: :A[ :B[ 'C', 'D' ], 'E' ], we download A-B-E-C-D
        #       and then build D-C-E-B-A. Though this works, one could
        #       conceive of a download preorder A-B-C-D-E and a build
        #       postorder C-D-B-E-A. Those could even be interspersed
        #       build-soonest, making it dA-dB-dC-bC-bD-bB-dE-bE-bA.
        my %seen;
        for @projects -> $top-project {
            next if %seen{$top-project};
            my @build-stack = $top-project;
            my @fetch-queue = $top-project;

            while @fetch-queue {
                my $project = @fetch-queue.shift;
                next if %seen{$project}++;
                self.fetch($project);
                my @deps = self.get-deps($project);
                @fetch-queue.push(@deps);
                @build-stack.unshift(@deps.reverse);
            }

            for @build-stack.uniq -> $project {
                self.build($project);
            }
        }
    }

    submethod fetch( Str $project ) {
        # RAKUDO: :exists [perl #59794]
        if !$.ecosystem.contains-project($project) {
            say "proto installer does not know about project '$project'";
            say 'Try updating proto to get the latest list of projects.';
            # TODO: It seems we can do better than this. A failed download
            #       does not invalidate a whole installation process, only the
            #       dependency tree in which it is a part. Passing information
            #       upwards with exceptions would provide excellent error
            #       diagnostics (either it failed because it wasn't found, or
            #       because dependencies couldn't be installed).
            exit 1;
        }
        my $target-dir = %!config-info{'Proto projects directory'}
                         ~ "/$project";
        my %info       = $.ecosystem.get-info-on($project);
        if %info.exists('type') && %info<type> eq 'bootstrap' {
            if $project eq 'proto' {
                $target-dir = '.';
            }
            else {
                die "Unknown bootstrapping project '$project'.";
            }
        }
        my $silently   = '>/dev/null 2>&1';
        if $target-dir ~~ :d {
            print "Updating $project...";
            my $indir = "cd $target-dir";
            my $command = do given %info<home> {
                when 'github' | 'gitorious' { 'git pull' }
                when 'googlecode'           { 'svn up' }
            };
            run( "$indir; $command $silently" );
            say 'updated';
        }
        else {
            print "Downloading $project...";
            my $name       = %info<name> // $project;
            my $command = do given %info<home> {
                when 'github' {
                    sprintf '(git clone   git@github.com:%s/%s.git %s ||'
                          ~ ' git clone git://github.com/%s/%s.git %s)',
                            (%info<owner>, $name, $target-dir) xx 2;
                }
                when 'gitorious' {
                    sprintf
                      '(git clone   git@gitorious.org:%s/mainline.git %s ||'
                    ~ ' git clone git://gitorious.org/%s/mainline.git %s)',
                      ($name, $target-dir) xx 2;
                }
                when 'googlecode' {
                    sprintf 'svn co https://%s.googlecode.com/svn/trunk %s',
                            $name, $target-dir;
                }
                default { die "Unknown home type {%info<home>}"; }
            };
            run( "$command $silently" );
            say 'downloaded';
        }
    }

    submethod build( Str $project ) {
        print "Building $project...";
        # RAKUDO: Doesn't support any other way to change the current working
        #         directory. Improvising.
        my %info        = $.ecosystem.get-info-on($project);
        my $target-dir  = %!config-info{'Proto projects directory'}
                          ~ "/$project";
        if %info.exists('type') && %info<type> eq 'bootstrap' {
            if $project eq 'proto' {
                $target-dir = '.';
            }
            else {
                die "Unknown bootstrapping project '$project'.";
            }
        }
        my $project-dir = $target-dir;
        if defined %info<main_subdir> {
            $project-dir = %info<main_subdir>;
        }
        my $in-dir = "cd $project-dir";
        # RAKUDO: Can't really figure out how to set environment variables
        #         so they're visible by later commands. Doing like this
        #         instead.
        my $p6lib
            = 'env PERL6LIB='
                ~ join ':', map {
                      "{%!config-info{'Proto projects directory'}}/$_/lib"
                  }, $project, self.get-deps-deeply( $project );
        my $perl6 = %!config-info{'Rakudo directory'} ~ '/perl6';
        # XXX: Need to have error handling here, and not continue if things go
        #      haywire with the build. However, a project may not have a
        #      Makefile.PL or Configure.p6, and this needs to be considered
        #     a successful [sic] outcome.
        for <Makefile.PL Configure.pl Configure.p6 configure> -> $config-file {
            if "$project-dir/$config-file" ~~ :f {
                my $perl = $config-file eq 'Makefile.PL'
                    ?? 'perl'
                    !! "{%*ENV<RAKUDO_DIR>}/perl6";
                my $conf-cmd
                    = "$in-dir; $p6lib $perl $config-file > make.log 2>\&1";
                run( $conf-cmd );
                last;
            }
        }
        my $make-cmd = "$in-dir; $p6lib make >> make.log 2>\&1";
        run( $make-cmd );
        say 'built';
#       unlink( "$project-dir/make.log" );
    }

    method not-implemented($subcommand) {
        warn "The '$subcommand' subcommand is not implemented yet.";
    }

    submethod get-deps($project) {
        my $deps-file = %!config-info{'Proto projects directory'}
                        ~ "/$project/deps.proto";
        return unless $deps-file ~~ :f;
        my &remove-line-ending-comment = { .subst(/ '#' .* $ /, '') };
        return lines($deps-file)\
                 .map({remove-line-ending-comment($^line)})\
                 .map(*.trim)\
                 .grep({$^keep-all-nonempty-lines});
    }

    # TODO: This is a nice, short algorithm and all, but we need to make sure
    #       we don't get stuck in a cycle. Passing the projects up the call
    #       stack as an optional param would probably work.
    submethod get-deps-deeply($project) {
        my @deps = self.get-deps( $project );
        for @deps -> $dep {
            my @deps-of-dep = self.get-deps-deeply( $dep );
            @deps.push( @deps-of-dep );
        }
        return @deps.uniq;
    }

    sub load-config-file(Str $filename) {
        my %settings;
        for lines($filename) {
            when /^ '---'/ {
                # do nothing
            }
            when / '#' (.*) $/ {
                # do nothing
            }
            when / (.*) ':' \s+ (.*) / {
                %settings{$0} = $1;
            }
        }
        return %settings;
    }
}

# vim: ft=perl6
