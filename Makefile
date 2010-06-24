PERL6=perl6
PERL6LIB='/Users/masak/gwork/proto/lib'

SOURCES=lib/App/Pls.pm \
        lib/JSON/Tiny/Actions.pm lib/JSON/Tiny/Grammar.pm lib/JSON/Tiny.pm

PIRS=$(patsubst %.pm6,%.pir,$(SOURCES:.pm=.pir))

.PHONY: test clean

all: $(PIRS)

%.pir: %.pm
	env PERL6LIB=$(PERL6LIB) $(PERL6) --target=pir --output=$@ $<

%.pir: %.pm6
	env PERL6LIB=$(PERL6LIB) $(PERL6) --target=pir --output=$@ $<

clean:
	rm -f $(PIRS)

test: all
	env PERL6LIB=$(PERL6LIB) prove -e '$(PERL6)' -r --nocolor t/

install: all
	install -D lib/App/Pls.pir ~/.perl6/lib/App/Pls.pir
	install -D lib/JSON/Tiny/Actions.pir ~/.perl6/lib/JSON/Tiny/Actions.pir
	install -D lib/JSON/Tiny/Grammar.pir ~/.perl6/lib/JSON/Tiny/Grammar.pir
	install -D lib/JSON/Tiny.pir ~/.perl6/lib/JSON/Tiny.pir

install-src:
	install -D lib/App/Pls.pm ~/.perl6/lib/App/Pls.pm
	install -D lib/JSON/Tiny/Actions.pm ~/.perl6/lib/JSON/Tiny/Actions.pm
	install -D lib/JSON/Tiny/Grammar.pm ~/.perl6/lib/JSON/Tiny/Grammar.pm
	install -D lib/JSON/Tiny.pm ~/.perl6/lib/JSON/Tiny.pm
