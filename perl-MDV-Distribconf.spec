%define dist	MDV-Distribconf
%define version	1.00
%define release	1mdk

Summary:	Perl module to get config from a Mandriva Linux distribution tree
Name:		perl-%{dist}
Version:	%{version}
Release:	%{release}
License:	GPL
Group:		Development/Perl
Source0:	%{dist}-%{version}.tar.bz2
Url:		http://cvs.mandriva.com/cgi-bin/cvsweb.cgi/soft/perl-%{dist}/
BuildRoot:	%{_tmppath}/%{name}-buildroot/
BuildArch:	noarch

%description
MDV::Distribconf is a module to get/write the configuration of a Mandriva Linux
distribution tree.

%prep
%setup -q -n %{dist}-%{version}

%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
%{__make}

%check
%{__make} test

%install
rm -rf $RPM_BUILD_ROOT
%makeinstall_std

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc ChangeLog
%{_mandir}/*/*
%{perl_vendorlib}/MDV/Distribconf
%{perl_vendorlib}/MDV/Distribconf.pm

%changelog
* Fri Oct 28 2005 Rafael Garcia-Suarez <rgarciasuarez@mandriva.com> 1.00-1mdk
- Initial MDV release
