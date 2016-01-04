#!/home/modules.perl6.org/perl5/perlbrew/perls/perl-5.22.0/bin/perl

eval 'exec /home/modules.perl6.org/perl5/perlbrew/perls/perl-5.22.0/bin/perl -S $0 ${1+"$@"}'
    if 0; # not running under some shell

### BEGIN INIT INFO
# Provides:          modules.perl6.org-init.d
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: modules.perl6.org-init.d web application
### END INIT INFO


use Toadfarm -init;
run_as "modules.perl6.org";
mount "/home/modules.perl6.org/modules.perl6.org/bin/ModulesPerl6.pl";
start [ "http://*:3333" ], proxy => 1, workers => 8;
