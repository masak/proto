#!/usr/bin/env perl

use FindBin;
use 5.014;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

require Mojolicious::Commands;
Mojolicious::Commands->start_app('ModulesPerl6');

__END__

=encoding utf8

=head1 USAGE

    Usage: hypnotoad [OPTIONS] [APPLICATION]

      hypnotoad ./script/my_app
      hypnotoad ./myapp.pl
      hypnotoad -f ./myapp.pl

    Options:
      -f, --foreground   Keep manager process in foreground
      -h, --help         Show this message
      -s, --stop         Stop server gracefully
      -t, --test         Test application and exit

=head1 CONTACT INFORMATION

Original version of this code was written by Zoffix Znet
(L<https://github.com/zoffixznet/>, C<Zoffix> on irc.freenode.net).

=head1 LICENSE

You can use and distribute this code under the same terms as Perl itself.
