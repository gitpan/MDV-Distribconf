#!/usr/bin/perl

# $Id: 01distribconf.t 56934 2006-08-21 10:16:29Z nanardon $

use strict;
use Test::More;
use MDV::Distribconf;

my @testdpath = glob('testdata/history/*/*/*');

plan tests => 3 * scalar(@testdpath);

foreach my $path (@testdpath) {
    ok(
        my $dconf = MDV::Distribconf->new($path),
        "Can get new MDV::Distribconf"
    );
    ok($dconf->load(), "can load $path");
    ok($dconf->listmedia(), "can list media");
}
