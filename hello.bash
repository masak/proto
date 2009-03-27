#!/bin/bash
#
# NAME
# hello.bash - a canonical "hello, world!" project for proto
#
# SYNOPSIS
# bash hello.bash      # creates and uploads everything in /tmp/hello
#
# DESCRIPTION
# Implements proto's PIONEER plan in code

cat <<EOF

This is 'hello.bash', a project generator for masak's 'proto' installer.
You first need to have done the following:

1. Create a github account at https://github.com/signup/free
2. Login to your github account: https://github.com/login
3. Create a new repository: http://github.com/repositories/new
4. Enter your Project Name, Description, optional Homepage and click Create.
5. This script will take care of the 'Next steps:' part.

If 'Create' worked, continue with this script, otherwise type Control-C to exit.

EOF
echo -n 'Git username :'
read GITUSER
echo -n 'Project name :'
read PROJECT
export GITUSER PROJECT
#Currently using github username $GITUSER, project name $PROJECT.
#Edit this script to change those.

# Begin with some steps from "Create New Repository" at github.com
cd /tmp
rm -rf $PROJECT       # ensure a clean start every time
mkdir $PROJECT
cd $PROJECT
mkdir lib t
git init

# The project should consist mainly of Perl modules.
# Module files contain classes, roles, grammars and documentation.
mkdir lib/Example
cat >lib/Example/Hello.pm <<EOF
class Example::Hello
{
    method greet { return "hello" }
    method place { return "world" }
}
=begin pod
=head1 NAME
Example::Hello - canonical "hello, world!" project for proto
=head1 AUTHOR
$GITUSER ($GITUSER at github.com and @email.com)
=end pod
EOF

# Include a test suite to improve your karma (and your code quality)
# Beware the \ escapes for bash:
cat >t/01-simple.t <<EOF
use Example::Hello;
use Test;
plan 3;
my Example::Hello \$greeter .= new;
isa_ok( \$greeter, 'Example::Hello', 'create object' );
is( \$greeter.greet, 'hello', 'greet' );
is( \$greeter.place, 'world', 'place' );
EOF

# Create a Makefile.in like this example from mattw's form project.
# note the \$ escaping to play nicely with bash.
cat >Makefile.in <<EOF
PERL6=<PERL6>
PERL6LIB=<PERL6LIB>
RAKUDO_DIR=<RAKUDO_DIR>

SOURCES=lib/Example/Hello.pm


PIRS=\$(SOURCES:.pm=.pir)

all: \$(PIRS) lib/Test.pir

%.pir: %.pm
	\$(PERL6) --target=pir --output=\$@ \$<

lib/Test.pir: \$(RAKUDO_DIR)/Test.pm \$(PERL6)
	\$(PERL6) --target=pir --output=lib/Test.pir \$(RAKUDO_DIR)/Test.pm

clean:
	rm -f \$(PIRS)

tests: test

test: all
	PERL6LIB=\$(PERL6LIB) prove -e '\$(PERL6)' -r --nocolor t/
EOF

# The above 'Makefile.in' needs something active to convert it into a
# Makefile. There is a Configure.pm in proto that is invoked by the
# following Perl 6 script:
cat >Configure.p6 <<EOF
# Configure.p6 - installer - see documentation in ../Configure.pm
use v6; BEGIN { @*INC.push( '../..' ); }; use Configure; # proto dir
EOF

# Notify proto about dependencies on other modules. The installer will
# ensure that PERL6LIB can also find the content of their lib
# directories so that 'use thatmodule;' Just Works.
cat >deps.proto <<EOF
form
EOF

# Some more steps from "Create New Repository" at github.com
git add deps.proto Makefile* Configure.p6 lib/Example/* t/*
git commit -m "created by hello.bash from masak's proto"
git remote add origin git@github.com:$GITUSER/$PROJECT.git
git push origin master

# Add these lines to proto's modules.list
cat <<EOF

6. If there were NO errors above, your repository on github should be ready:
   in your browser click on "When you're done: Continue" or
   http://github.com/$GITUSER/$PROJECT/tree/master

7. Ask a proto maintainer to add these lines to 'modules.list', or simply
   edit your local copy:
$PROJECT:
    home:   github
    owner:  $GITUSER

8. Then you should be able to install your project:
   ./proto install $PROJECT

Now your work really starts :)

9. Replace proto/projects/$PROJECT/lib/Example/Hello.pm with your module file(s)
   and update SOURCES in proto/projects/$PROJECT/Makefile.in accordingly.
   Run 'perl Makefile.PL' after each change to Makefile.in.
10. Add README, LICENCE and other instructions.
11. Revise and extend proto/projects/$PROJECT/t/01-simple.t as well, and run
    'make test' after every change that affects execution of your code.
12. Use 'git push' early and often.

EOF
