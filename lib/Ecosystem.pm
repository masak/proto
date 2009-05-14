class Ecosystem;

has $projects-dir;
has %!project-info;

method new(:$projects-dir!) {
    self.bless(
        projects-dir => $projects-dir,
        project-info => load-project-list('projects.list'),
    );
}

method contains-project($project) {
    # RAKUDO: :exists [perl #59794]
    return %!project-info.exists($project);
}

method get-info-on($project) {
    return %!project-info{$project};
}

method regular-projects() {
    return %!project-info.keys.grep:
        { !%!project-info{$_}.exists('type')
          || !(%!project-info{$_}<type> eq 'pseudo'|'bootstrap') };
}

method installed-projects() {
    return self.regular-projects.grep: { "$projects-dir/$_" ~~ :d };
}

method uninstalled-projects() {
    return self.regular-projects.grep: { "$projects-dir/$_" !~~ :d };
}

sub load-project-list(Str $filename) {
    my $fh = open($filename)
        or die "Can't open '$filename': $!";

    my %overall;
    my $current-name;
    my %current;
    for $fh.lines {
        when / ^ \s* ['#' | $ ] /   { next };
        when / ^ (\S+) \: \s* ['#' | $ ] / {
            if $current-name.defined {
                %overall{$current-name} = %current.clone;
            }
            %current = ();
            $current-name = ~$0;
        }
        when / ^ \s+ (\S+) ':' \s* (\S+) \s* ['#' | $ ] / {
            %current{~$0} = ~$1;
        }
        default {
            warn "don't know how to parse the line «$_», ignoring it"
        }
    }
    if %current {
        %overall{$current-name} = %current;
    }

    return %overall;
}

# vim: ft=perl6
