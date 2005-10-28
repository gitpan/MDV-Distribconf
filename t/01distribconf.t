#!/usr/bin/perl

# $Id: 01distribconf.t,v 1.2 2005/10/09 22:12:33 othauvin Exp $

use strict;
use Test::More tests => 16;

use_ok('MDV::Distribconf');

{
ok(my $dconf = MDV::Distribconf->new('/dev/null'), "Can get new MDV::Distribconf");
ok(!$dconf->load(), "loading wrong distrib give error");
}

ok(my $dconf = MDV::Distribconf->new('test'), "Can get new MDV::Distribconf");
ok($dconf->load(), "Can load conf");

ok(scalar($dconf->listmedia) == 8, "Can list all media");
ok(grep { $_ eq 'main' } $dconf->listmedia, "list properly media");

ok($dconf->getvalue(undef, 'version') eq '2006.0', "Can get global value");
ok($dconf->getvalue('main', 'version') eq '2006.0', "Can get global value via media");
ok($dconf->getvalue('main', 'name') eq 'main', "Can get default name");
ok($dconf->getvalue('contrib', 'name') eq 'Contrib', "Can get media name");

ok($dconf->getpath(undef, 'root') eq 'test', "Can get root path");
ok($dconf->getpath(undef, 'media_info') =~ m!^/*media/media_info/?$!, "Can get media_info path"); # vim color: */ 
ok($dconf->getfullpath(undef, 'media_info') =~ m!^/*test/+media/media_info/?$!, "Can get media_info fullpath"); # vim color: */
ok($dconf->getpath('main', 'path') =~ m!^/*media/+main/?$!, "Can get media path"); # vim color: */
ok($dconf->getfullpath('main', 'path') =~ m!^/*test/*media/+main/?$!, "Can get media fullpath"); # vim color: */

