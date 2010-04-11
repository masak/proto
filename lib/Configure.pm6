# Configure.pm6

.say for
    '',
    'Configure.pm6 is preparing to make your Makefile.',
    '';

# Determine how this Configure was invoked, to write the same paths and
# executables into the Makefile variables. The variables are:
# PERL6       how to execute a Perl 6 script
# PERL6LIB    part of @*INC, where 'use <module>;' searches

my $perl6    = $*EXECUTABLE_NAME;
my $perl6lib = %*ENV<PERL6LIB>.index(%*ENV<PWD> ~ '/lib').defined
               ?? %*ENV<PERL6LIB>
               !! %*ENV<PWD> ~ '/lib';
say "PERL6       $perl6";
say "PERL6LIB    $perl6lib";

# Read Makefile.in, edit, write Makefile
my $maketext = slurp( 'Makefile.in' );
$maketext .= subst( .key, .value ) for
    'Makefile.in'       => 'Makefile',
    'To be read'        => 'Written',
    'replaces <TOKENS>' => 'defined these',
    # Maintainer note: keep these in sync with pod#VARIABLES below
    '<PERL6>'           => $perl6,
    '<PERL6LIB>'        => $perl6lib;
squirt( 'Makefile', $maketext );

# Job done.
.say for
    "",
    "Makefile is ready.  You can run 'make', 'make help' and so on.";

# The opposite of slurp
sub squirt( Str $filename, Str $text ) {
    my $handle = open( $filename, :w )
        or die $!;
    $handle.print: $text;
    $handle.close;
}

=begin pod

=head1 NAME
Configure.pm6 - common code for a Makefile builder

=head1 SYNOPSIS

 perl6 Configure

Where F<Configure.p6> generally has only these lines:

 # Configure - Makefile builder - docs in Configure.pm6
 use v6; BEGIN { @*INC.unshift('lib'); }; use Configure;

=head1 DESCRIPTION
A Perl project often needs a Makefile to specify how to build, test and
install it.  Makefiles must often be adjusted slightly to alter the
context in which they will work.  There are various tools to
"make Makefiles" and this F<Configure> and F<Configure.pm6> combination
do the job purely in Perl 6.

F<Configure> resides in the project top level directory. For covenience,
F<Configure> usually contains only the lines shown in L<doc:#SYNOPSIS>
above, namely a comment and one line of code to pass execution to
F<Configure.pm6>. Any custom actions to prepare the module can be called
by the default target in F<Makefile.in>.

F<Configure> reads F<Makefile.in> from the module top level directory,
replaces certain variables marked like <THIS>, and writes the updated
text to F<Makefile> in the same directory.

=head1 VARIABLES
F<Configure> will cause the following tokens to be substituted when
creating the new F<Makefile>:

 <PERL6>        full path of Perl 6 (fake)executable
 <PERL6LIB>     lib/ directory of the installed project

=head1 AUTHOR
Martin Berends (mberends on CPAN github #perl6 and @autoexec.demon.nl).

=end pod
