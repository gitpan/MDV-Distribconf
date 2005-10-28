# $Id: Makefile.PL,v 1.3 2005/10/28 09:46:07 rgarciasuarez Exp $

use 5.008;
use strict;
use ExtUtils::MakeMaker;

# where to find the rpm utility
my $rpm_path = $ENV{RPM_PATH}; # this overrides
unless (defined $rpm_path) {
    for (qw(/bin/rpm /usr/bin/rpm)) {
	if (-x) {
	    $rpm_path = $_;
	    last;
	}
    }
}
my $rpmtopdir = $rpm_path ? `$rpm_path --eval '%{_topdir}'` : '';
chomp $rpmtopdir;

sub MY::postamble {
    <<MAKE;
.PHONY: ChangeLog rpmdist srpm rpm

ChangeLog: ../common/username
	cvs2cl -W 400 -I ChangeLog --accum -U ../common/username
	rm -f *.bak

rpmdist: dist
	cp -f perl-MDV-Distribconf.spec $rpmtopdir/SPECS
	bzme MDV-Distribconf-*.tar.gz
	mv -f MDV-Distribconf-*.tar.bz2 $rpmtopdir/SOURCES

srpm: rpmdist
	rpmbuild -bs --clean --rmsource $rpmtopdir/SPECS/perl-MDV-Distribconf.spec

rpm: rpmdist
	rpmbuild -ba --clean --rmsource $rpmtopdir/SPECS/perl-MDV-Distribconf.spec
MAKE
}

WriteMakefile(
    NAME	 => 'MDV::Distribconf',
    VERSION_FROM => 'lib/MDV/Distribconf.pm',
);
