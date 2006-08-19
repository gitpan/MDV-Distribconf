#!/usr/bin/perl

# $Id: 01distribconf.t 56863 2006-08-19 00:55:51Z nanardon $

use strict;
use Test::More tests => 35;

use_ok('MDV::Distribconf');

{
ok(my $dconf = MDV::Distribconf->new('/dev/null'), "Can get new MDV::Distribconf");
ok(!$dconf->load(), "loading wrong distrib give error");
}

foreach my $path (qw(testdata/test testdata/test2)) {
    ok(my $dconf = MDV::Distribconf->new($path), "Can get new MDV::Distribconf");
    ok($dconf->load(), "Can load conf");

    ok(scalar($dconf->listmedia) == 8, "Can list all media");
    ok(grep { $_ eq 'main' } $dconf->listmedia, "list properly media");

    ok($dconf->getvalue(undef, 'version') eq '2006.0', "Can get global value");
    ok($dconf->getvalue('main', 'version') eq '2006.0', "Can get global value via media");
    ok($dconf->getvalue('main', 'name') eq 'main', "Can get default name");
    ok($dconf->getvalue('contrib', 'name') eq 'Contrib', "Can get media name");

    ok($dconf->getpath(undef, 'root') eq $path, "Can get root path");
    ok($dconf->getpath(undef, 'media_info') =~ m!^/*media/media_info/?$!, "Can get media_info path"); # vim color: */ 
    ok($dconf->getfullpath(undef, 'media_info') =~ m!^/*$path/+media/media_info/?$!, "Can get media_info fullpath"); # vim color: */
    ok($dconf->getpath('main', 'path') =~ m!^/*media/+main/?$!, "Can get media path"); # vim color: */
    ok($dconf->getfullpath('main', 'path') =~ m!^/*$path/*media/+main/?$!, "Can get media fullpath"); # vim color: */
}

{
ok(my $dconf = MDV::Distribconf->new('not_exists', 1), "Can get new MDV::Distribconf");
$dconf->settree();
ok($dconf->getpath(undef, 'media_info') =~ m!^/*media/media_info/?$!, "Can get media_info path"); # vim color: */
}
{
ok(my $dconf = MDV::Distribconf->new('not_exists', 1), "Can get new MDV::Distribconf");
$dconf->settree('manDraKE');
ok($dconf->getpath(undef, 'media_info') =~ m!^/*Mandrake/base/?$!, "Can get media_info path"); # vim color: */
}
{
ok(my $dconf = MDV::Distribconf->new('not_exists', 1), "Can get new MDV::Distribconf");
$dconf->settree({ 
  mediadir => 'mediadir',
  infodir => 'infodir',
});
ok($dconf->getpath(undef, 'media_info') =~ m!^/*infodir/?$!, "Can get media_info path"); # vim color: */
}
