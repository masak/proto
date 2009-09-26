use v6;
use Ecosystem;

class Installer {
    has %!config-info;
    has Ecosystem $.ecosystem;

    method new() {
        self.bless(
            self.CREATE(),
            config-info => (my $c = load-config-file('config.proto')),
            ecosystem   => Ecosystem.new(cache-dir => $c{'Proto projects cache'}),
        )
    }

    my @available-commands = <fetch refresh clean test install uninstall showdeps showstate help>; #TODO: add update

    # Returns a block which calls the right subcommand with a variable number
    # of parameters. If the provided subcommand is unknown or undef, this
    # method exits immediately.
    method subcommand-dispatch($command) {
        given $command {
            when undef                    { exit }
            when any(@available-commands) {} # fall out, approved
            default {
                say "Unrecognized subcommand '$command'.";
                self.help();
                exit;
            }
        };
        return eval sprintf '{ -> *@projects { self.%s( @projects) } }',
                            $command;
    }

    method help(@projects) {
        .say for
            "A typical usage is:",
            q['./proto install <projectname>'],
            'Available commands: ' ~ @available-commands,
            'See the README for more details';
    }

    method fetch-or-refresh($subcommand, @projects) {
        my @projects-to-fetch;
        my $missing-projects = False;
        for @projects -> $project {
            if !$.ecosystem.contains-project($project) {
                say "Project not found: '$project'";
                $missing-projects = True;
            }
            elsif $project eq 'all' {
                @projects-to-fetch.push($.ecosystem.unfetched-projects());
            }
            elsif $subcommand eq "fetch" && $.ecosystem.is-state($project,'fetched') {
                say "Won't fetch $project: already fetched.";
            }
            elsif $subcommand eq "refresh" && !$.ecosystem.is-state($project,'fetched') {
                say "Cannot refresh $project: not fetched.";
            }
            else {
                @projects-to-fetch.push($project);
            }
        }
        if $missing-projects {
            say 'Try updating proto to get the latest list of projects.';
            exit(1);
        }
        if !@projects-to-fetch {
            say 'Nothing to fetch.';
            exit(1);
        }
        @projects-to-fetch .= uniq;
        my @projects-to-build = self.download-projects-and-their-deps( @projects-to-fetch );
        for @projects-to-build -> $project { self.build($project) }
        if $subcommand eq 'fetch' {
            self.check-if-in-perl6lib( @projects-to-fetch );
        }
    }

    method fetch(@projects) {
        self.fetch-or-refresh( 'fetch', @projects );
    }

    method refresh(@projects) {
        self.fetch-or-refresh( 'refresh', @projects );
    }

    method clean(@projects is copy) {
        if @projects.grep('all') {
            @projects=$.ecosystem.regular-projects.sort;
        }
        for @projects -> $project {
            if !$.ecosystem.contains-project($project) {
                say "proto does not know about $project: skipping";
            }
            elsif $.ecosystem.is-state($project,'fetched') {
                print "Cleaning $project...";
                my $target-dir = %!config-info{'Proto projects cache'}
                                 ~ "/$project";
                run("rm -rf $target-dir");
                $.ecosystem.set-state($project,'');
                say "done";
            }
            else {
                say "$project was already cleaned";
            }
        }
    }

    method test(@projects) {
        unless @projects {
            say 'You have to specify what you want to test.';
            # TODO: Maybe just test everything fetched?
            #       YES: cheese speleology!
            exit 1;
        }
        my $can-continue = True;
        for @projects -> $project {
            unless $.ecosystem.contains-project($project) {
                say "Project not found: '$project'";
                $can-continue = False;
            }
            unless $.ecosystem.get-state($project) eq 'built' {
                say "Project '$project' is not downloaded";
                $can-continue = False;
            }
        }
        unless $can-continue {
            say "Aborting...";
            exit(1);
        }
        for @projects -> $project {
            my $project-dir = $.ecosystem.project-dir($project);
            print "Testing $project...";
            my $command = '';
            if "$project-dir/Makefile" ~~ :e {
                if slurp("$project-dir/Makefile") ~~ /^test:/ {
                    $command = 'make test';
                }
            }
            unless $command {
                if "$project-dir/t" ~~ :d
                    && any(map { "$_/prove" }, %*ENV<PATH>.split(":")) ~~ :e
                {
                    $command = 'prove -e "'
                        ~ %!config-info{'Perl 6 executable'}
                        ~ '" -r --nocolor t/';
                }
            }
            if $command {
                my $r = self.configured-run( $command, :project( $project ), :dir( $project-dir ) );
                if $r != 0 {
                    say 'failed';
                    $.ecosystem.set-state($project,'test-failed');
                    return;
                }
            }
            say 'ok';
            $.ecosystem.set-state($project,'tested');
        }
    }

    # TODO: This sub should probably recursively show dependencies, and in
    #       such a way that a dependency found twice by different routes is
    #       only mentioned the second time -- its dependencies are not shown.
    method showdeps(@projects) {
        unless @projects {
            say "You have to specify which projects' dependencies to show.";
            exit 1;
        }
        for @projects -> $project {
            if !$.ecosystem.is-state($project,'fetched') {
                say "$project is not here.";
            }
            elsif !self.get-deps($project) {
                say "$project has no dependencies.";
            }
            else {
                self.showdeps-recursively($project);
            }
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

    method showstate(@projects is copy) {
        if @projects.grep('all') { @projects=$.ecosystem.regular-projects.sort; }
        unless @projects { say "No projects requested"; return; }
        for @projects -> $p { say "$p: {$.ecosystem.get-state($p)}"; }
    }

    submethod download-projects-and-their-deps(@projects) {
        # TODO: Though the below traversal works, it seems much cooler to do
        #       builds as soon as possible. Right now, in a dep tree looking
        #       like this: :A[ :B[ 'C', 'D' ], 'E' ], we download A-B-E-C-D
        #       and then build D-C-E-B-A. Though this works, one could
        #       conceive of a download preorder A-B-C-D-E and a build
        #       postorder C-D-B-E-A. Those could even be interspersed
        #       build-soonest, making it dA-dB-dC-bC-bD-bB-dE-bE-bA.
        my %seen;
        my @build-stack;
        for @projects -> $top-project {
            next if %seen{$top-project};
            @build-stack.push($top-project);
            my @download-queue = $top-project;

            while @download-queue {
                my $project = @download-queue.shift;
                next if %seen{$project}++;
                self.download($project);
                my @deps = self.get-deps($project);
                @download-queue.push(@deps);
                @build-stack.unshift(@deps.reverse);
            }

#           for @build-stack.uniq -> $project {
#               self.build($project);
#           }
        }
        return @build-stack.uniq;
    }

    submethod download( Str $project ) {
        # RAKUDO: :exists [perl #59794]
        if !$.ecosystem.contains-project($project) {
            say "proto installer does not know about project '$project'";
            say 'Try updating proto to get the latest list of projects.';
            # TODO: It seems we can do better than this. A failed download
            #       does not invalidate a whole installation process, only the
            #       dependency tree in which it is a part. Passing information
            #       upwards with exceptions would provide excellent error
            #       diagnostics (either it failed because it wasn't found, or
            #       because dependencies couldn't be fetched).
            exit 1;
        }
        my $target-dir = %!config-info{'Proto projects cache'}
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
        if $.ecosystem.is-state($project,'fetched') {
            print "Refreshing $project...";
            my $command = do given %info<home> {
                when 'github' | 'gitorious' { 'git pull' }
                when 'googlecode'           { 'svn up' }
            };
            my $state = self.configured-run( $command, :dir( $target-dir ) )
                ?? 'failed' !! 'updated';
            say $state;
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
                default {
                    die "Unknown home type '{%info<home>}' for project '$project'";
                }
            };
            # This fails since there are parens in $command
            #self.configured-run( $command );
            my $state = run( "$command $silently" )
                ?? 'failed' !! 'downloaded';
            say $state;
        }
    }

    submethod build( Str $project ) {
        print "Building $project...";
        # RAKUDO: Doesn't support any other way to change the current working
        #         directory. Improvising.
        my %info        = $.ecosystem.get-info-on($project);
        my $target-dir  = %!config-info{'Proto projects cache'}
                          ~ "/$project";
        if %info.exists('type') && %info<type> eq 'bootstrap' {
            die "Unknown bootstrapping project '$project'."
                unless $project eq 'proto';
            $target-dir = '.';
        }
        my $project-dir = $target-dir;
        if defined %info<main_subdir> {
            $project-dir = %info<main_subdir>;
        }
        # XXX: Need to have error handling here, and not continue if things go
        #      haywire with the build. However, a project may not have a
        #      Makefile.PL or Configure.p6, and this needs to be considered
        #      a successful [sic] outcome.
        # TODO: deprecate PARROT_DIR and RAKUDO_DIR now that we have an
        #       installed Perl 6 executable.
        %*ENV<PARROT_DIR> = %*VM<config><bindir>;
        %*ENV<RAKUDO_DIR> = %*VM<config><bindir>; # same, in parrot_install
        my $perl6 = %!config-info{'Perl 6 executable'};
#       if $perl6 ~~ / (.*) \/ perl6 / { %*ENV<RAKUDO_DIR> = $0; }
        for <Makefile.PL Configure.pl Configure.p6 Configure> -> $config-file {
            if "$project-dir/$config-file" ~~ :f {
                my $perl = $config-file eq 'Makefile.PL'
                    ?? 'perl'
                    !! $perl6;
                my $conf-cmd = "$perl $config-file";
                my $r = self.configured-run( $conf-cmd, :project{$project}, :dir{$project-dir} );
                if $r != 0 {
                    say "configure failed, see $project-dir/make.log";
                    return;
                }
                last;
            }
        }
        if "$project-dir/Makefile" ~~ :f {
            my $make-cmd = 'make';
            my $r = self.configured-run( $make-cmd, :project( $project ), :dir( $project-dir ) );
            if $r != 0 {
                $.ecosystem.set-state($project,'build-failed');
                say "build failed, see $project-dir/make.log";
                return;
            }
        }
        say 'built';
        $.ecosystem.set-state($project,'built');
        unlink( "$project-dir/make.log" );
    }

    method install(@projects) {
        # ensure all requested projects have been fetched, built and tested.
        # abort if any project is faulty.
        my @projects-to-download;
        for @projects -> $project {
            my $state = $.ecosystem.get-state($project);
            if $state eq any(<failed broken build-failed>) {
                say "Can't install, $project $state";
                return;
            }
            next if $state eq any('tested', 'installed');
            @projects-to-download.push: $project;
        }
        my @projects-to-build = self.download-projects-and-their-deps( @projects-to-download );
        for @projects-to-build -> $project { self.build($project) }

        # Add the built deps.
        # TODO: make sure that the project actually is installable.
        @projects.unshift( @projects.map({ self.get-deps-deeply( $_ )})\
                                    .grep({ $.ecosystem.get-state($_) ne 'installed' })
                         );
        # Install each project either via a custom copy by 'make install' if
        # available, or otherwise a default copy from lib/
        for @projects -> $project { # Makefile exists
            print "Installing $project...";
            if $.ecosystem.get-state($project) eq 'installed' {
                say 'already installed';
                next;
            }

            my $project-dir = $.ecosystem.project-dir($project);
            if "$project-dir/Makefile" ~~ :f && slurp("$project-dir/Makefile") ~~ /^install\:/ {
                my $r = self.configured-run( 'make install', :project( $project ), :dir( $project-dir ) );
                if $r != 0 {
                    $.ecosystem.set-state($project,'install-failed');
                    say "install failed, see $project-dir/make.log";
                    return;
                }
            }
            else {
                # no Makefile, recursively install lib/*
                my $perl6lib = %!config-info{'Perl 6 library'};

                # Making sure we don't clobber anything
                my @files = $.ecosystem.files-in-cache-lib($project);
                # the Test and Configure modules from any project are
                # not welcome in the shared Perl 6 library
                # TODO: skip $file if eq any('Test.pm','Test.pir');
                # TODO: skip $file if eq any('Configure.pm','Configure.pir');
                for @files -> $file {
                    my $destination = $perl6lib ~ '/' ~ $file;
                    if $destination ~~ :f {
                        say "won't install since the file '$destination' already exists";
                        return False;
                    }
                }
                # If the previous loop ran to completion, copy all files
                # except Test.pm etc one by one.
                for @files -> $file {
                    my @names = split /\/|\\/, $file; # find dirs by / or \
                    my $filepart = @names.pop;
                    next if $filepart eq any(<Test.pm Configure.pm>);
                    if @names.elems {
                        my $dir = $perl6lib ~ '/' ~ join('/',@names);
                        if $dir !~~ :d {
                            run("mkdir $dir"); # TODO: change to IO::Path::create()
                        }
                    }
                    # TODO: a non clobbering, OS neutral alternative to
                    #       cp, replace with slurp() and squirt()
                    my $command = "cp $project-dir/lib/$file $perl6lib/$file";
                    my $status = run($command); # TODO: check status
                }
                # the old version that also copied Test.pm etc:
                # run("cp -r $project-dir/lib/* $perl6lib");
            }
            $.ecosystem.set-state($project, 'installed');
            say 'installed';
        }
    }

    method uninstall(@projects) {
        # Check that all projects are installed
        for @projects -> $project {
            if !$.ecosystem.is-state($project,'installed') {
                say "Can't uninstall $project - not installed";
                return False;
            }
        }
# TODO: Ensure the proposed uninstall does not break any dependencies.
#       This following was moved out of clean() and needs to be revised.
#       for $.ecosystem.fetched-projects() -> $project {
#           next if $project eq any(@projects);
#           for self.get-deps($project) -> $dep {
#               if $dep eq any(@projects) {
#                   say "Cannot clean $dep, depended on by $project.";
#                   say "Aborting.";
#                   return;
#               }
#           }
#       }

        my $perl6lib = %!config-info{'Perl 6 library'};
        for @projects -> $project {
            print "Uninstalling $project...";
            my $project-dir = $.ecosystem.project-dir($project);
            if "$project-dir/Makefile" ~~ :f && slurp("$project-dir/Makefile") ~~ /^uninstall\:/ {
                self.configured-run( 'make uninstall', :project( $project ), :dir( $project-dir ) );
            }
            else {
                for $.ecosystem.files-in-cache-lib($project).map({"$perl6lib/$_"}).grep({ $_ ~~ :f }) -> $file
                {
                    run("rm $file")
                }
            }
            # assume 'tested' preceded 'installed'
            $.ecosystem.set-state($project,
                $.ecosystem.is-state($project,'fetched')
                ?? 'tested' !! 'not-here' ); # TODO: erase state
            say 'done';
        }
    }

    method not-implemented($subcommand) {
        warn "The '$subcommand' subcommand is not implemented yet.";
    }

    submethod get-deps($project) {
        my $deps-file = %!config-info{'Proto projects cache'}
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

    submethod configured-run( Str $command, Str :$project = '',
                              Str :$dir = '.', Str :$output-mode = 'Log' ) {
        %*ENV<PERL6LIB> = join ':', map {
                              "{%!config-info{'Proto projects cache'}}/$_/lib"
                          }, $project, self.get-deps-deeply( $project );
        my $redirection = do given $output-mode {
            when 'Log'     { '>make.log 2>&1'  }
            when 'Silent'  { '>/dev/null 2>&1' }
            when 'Verbose' { ''                }
            default        { die               }
        };
        # Switch directory like this only in the child process,
        # so that the proto current directory does not have to change.
        my $cmd = "cd $dir; $command $redirection";
        run( $cmd );
    }

    sub load-config-file(Str $filename) {
        my %settings;
        for lines($filename) {
            when /^ '---'/               { }
            when / '#' (.*) $/           { }
            when / (.*) ':' <.ws> (.*) / { %settings{$0} = $1; }
        }
        return %settings;
    }

# TODO: replace with a central ~/.perl6/lib check
    submethod check-if-in-perl6lib( @projects ) {
        if %*ENV.exists('PERL6LIB') {
            my @projects-not-in
                = grep {
                    not "{%!config-info{'Proto projects cache'}}/$_/lib"
                        eq any(%*ENV<PERL6LIB>.split(':'))
                  }, @projects;
            if @projects-not-in {
                say 'The following projects are not in your $PERL6LIB env var: ',
                    ~@projects;
                say 'Please add them if you want to compile and run them outside '
                    ~ 'of proto.';
            }
        }
    }
}

# vim: ft=perl6
