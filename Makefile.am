#  Copyright (C) 2020 Tobias Oetiker

AUTOMAKE_OPTIONS =  foreign

SUBDIRS = bin lib thirdparty etc 

BIN = bin/$(MJ_SCRIPT).pl

PUB := $(shell find public -type d \( -name ".??*" -o -name transpiled \) -prune -o -not -name "*db.json" -a -not -name "*.map" -a -not -name "*~" -a -not -name transpiled -a -not -name "*.tmp"  -a -type f -print )
TEMPL := $(shell test -d templates && find templates -type f -name "*.ep")
SHARE := $(shell test -d share && find share -type d -name ".??*" -prune -o -not -name ".*" -a -not -name "*~" -a -not -name "*.tmp"  -a -type f -print)

PERLTESTS := $(shell find t -name "*.t")
PM := $(shell find lib -name "*.pm")

EXTRA_DIST = VERSION cpanfile COPYRIGHT LICENSE CHANGES AUTHORS bootstrap $(PUB) $(wildcard t/*.t) $(BIN) $(POD) $(TEMPL) $(PERLTESTS) $(SHARE)

YEAR := $(shell date +%Y)
DATE := $(shell date +%Y-%m-%d)

datadir = $(prefix)
nobase_data_DATA = $(PUB) $(TEMPL) $(SHARE)

README.md COPYRIGHT: VERSION
	$(PERL) -i -p -e 's/(#VERSION#|\d+\.\d+\.\d+[^.\s]*)/$(PACKAGE_VERSION)/g;s/(#YEAR#|20[1-9]\d)/$(YEAR)/g;s/(#DATE#|20[1-9]\d-[01]\d-[0-3]\d)/$(DATE)/g;' $@

dist-hook:
	$(PERL) -i -p -e 's/\$$VERSION\s*=\s*".+?";/\$$VERSION = "$(PACKAGE_VERSION)";/;'  $(distdir)/lib/$(MJ_CLASS).pm

install-exec-hook:
	[ "$(PERL5LIB)" == "" ] || cd "$(DESTDIR)$(exec_prefix)" && $(PERL) -i -p -e 's{.*# PERL5LIB}{use lib qw($(PERL5LIB)); # PERL5LIB}' $(BIN) || true
	cd "$(DESTDIR)$(exec_prefix)" && $(PERL) -i -p -e 's{.*# LIBDIR}{use lib qw($(libdir)); # LIBDIR}' $(BIN)
	cd "$(DESTDIR)$(exec_prefix)" && $(PERL) -i -p -e 's{^#!.*perl.*}{#!$(PERL)};' $(BIN)


test:
	prove -w
