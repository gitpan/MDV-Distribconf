#!/usr/bin/perl

# $Id: 01distribconf.t 56934 2006-08-21 10:16:29Z nanardon $

use strict;
use Test::More;

my @testdpath = qw(
    testdata/test
    testdata/test2
    testdata/test3
);

plan tests => 14 + 13 * scalar(@testdpath);

use_ok('MDV::Distribconf');

{
ok(my $dconf = MDV::Distribconf->new('/dev/null'), "Can get new MDV::Distribconf");
ok(!$dconf->load(), "loading wrong distrib give error");
}

foreach my $path (@testdpath) {
    ok(my $dconf = MDV::Distribconf->new($path), "Can get new MDV::Distribconf");
    ok($dconf->load(), "Can load conf");

    ok(scalar($dconf->listmedia) == 8, "Can list all media");
    ok((grep { $_ eq 'main' } $dconf->listmedia), "list properly media");

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

{
    # test for %{} ${} var
    my $dc = MDV::Distribconf->new('testdata/test3');
    $dc->load();
    is(
        $dc->_expand(undef, '${version}'),
        '2006.0',
        'expand works'
    );
    is(
        $dc->_expand('jpackage', '%{name}'),
        'jpackage',
        'expand works'
    );
    is(
        $dc->_expand('jpackage', '${version}'),
        '2006.0',
        'expand works'
    );
    is(
        $dc->_expand(undef, '%{foo}'),
        '%{foo}',
        'expand works'
    );
    is(
        $dc->getvalue('jpackage', 'hdlist'),
        'hdlist_jpackage.cz',
        'getvalue works'
    );
}
