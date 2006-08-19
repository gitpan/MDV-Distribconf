# $Id: Makefile.PL 56866 2006-08-19 01:16:31Z nanardon $

use 5.008;
use strict;
use ExtUtils::MakeMaker;

# where to find the rpm utility

sub MY::postamble {
    <<MAKE;
ChangeLog: \$(TO_INST_PM)
	svn2cl -o ChangeLog || :
	rm -f *.bak || :

change_dist: ChangeLog tardist

MAKE
}

WriteMakefile(
    NAME	 => 'MDV::Distribconf',
    VERSION_FROM => 'lib/MDV/Distribconf.pm',
    dist => { DIST_DEFAULT => 'change_dist' },
    EXE_FILES => [ qw(bin/checkdistrib) ],
);
