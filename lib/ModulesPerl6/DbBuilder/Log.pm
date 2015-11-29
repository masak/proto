package ModulesPerl6::DbBuilder::Log;

use Exporter::Easy EXPORT => [ 'log' ];
use Mojo::Log;

my $LOG = Mojo::Log->new;
sub log($$) {
    my ( $level, $message ) = @_;
    $LOG->$level( $message );
    $level eq 'fatal' and die "*died through fatal level log message*\n";

    return $message;
}

1;

__END__

=encoding utf8

=head1 NAME

ModulesPerl6::DbBuilder::Log - convenient logging

=head1 SYNOPSIS

    use ModulesPerl6::DbBuilder::Log;

    log info  => 'Starting stuff';
    log fatal => 'Oh noes!'; # dies after logging

    OUTPUT:
    [Sat Nov 21 12:12:30 2015] [info] Starting stuff
    [Sat Nov 21 12:12:30 2015] [fatal] Oh noes!
    *died through fatal level log message*

=head1 DESCRIPTION

This module is used to access and manipulate the database of Perl 6
distributions that is built by the build script.

=head1 EXPORTED SUBROUTINES

=head2 C<log>

    log info  => 'Starting stuff';
    log fatal => 'Oh noes!'; # dies after logging

B<Takes> log level and the log message and prints those along
with a time stamp. Valid log levels are C<debug>, C<info>, C<warn>,
C<error>, and c<fatal>. If C<fatal> log level is used, the subroutine will
C<die> after printing the error message.

=head1 CONTACT INFORMATION

Original version of this module was written by Zoffix Znet
(L<https://github.com/zoffixznet/>, C<Zoffix> on irc.freenode.net).

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
