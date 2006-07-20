# $Id: Makefile.PL 41764 2006-07-20 19:56:19Z nanardon $

use 5.008;
use strict;
use ExtUtils::MakeMaker;

# where to find the rpm utility

sub MY::postamble {
    <<MAKE;
.PHONY: ChangeLog

ChangeLog:
	svn2cl -o ChangeLog || :
	rm -f *.bak || :

MAKE
}

WriteMakefile(
    NAME	 => 'MDV::Distribconf',
    VERSION_FROM => 'lib/MDV/Distribconf.pm',
);
