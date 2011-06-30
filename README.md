# Perl 6 Modules

Source code for http://modules.perl6.org/

# How To Update modules.perl6.org

Currently, this website will only show up at http://perl6.github.com/modules.perl6.org/ until
the modules.perl6.org domain can be made a CNAME to pages.github.com .

    git checkout gh-pages       # switch to the github pages branch

    perl Build.PL

    ./Build installdeps         # install dependencies

    perl build-project-list.pl  # actually recreate the website (takes a while)
