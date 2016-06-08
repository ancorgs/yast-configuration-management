#
# spec file for package yast2-migration
#
# Copyright (c) 2016 SUSE LLC, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-scm
Version:        0.0.1
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Group:	        System/YaST
License:        GPL-2.0
Url:            http://github.com/yast/yast-migration

BuildRequires:	yast2
BuildRequires:	yast2-devtools
BuildRequires:  rubygem(rspec)
BuildRequires:  rubygem(yast-rake)
BuildRequires:  yast2-installation

Requires:	yast2
Requires:       yast2-installation

BuildArch: noarch

Summary:	YaST2 - YaST SCM

%description
This package contains the YaST2 component for SCM provisioning.

%prep
%setup -n %{name}-%{version}

%check
rake test:unit

%build

%install
rake install DESTDIR="%{buildroot}"

%files
%defattr(-,root,root)
%{yast_clientdir}/*.rb
%{yast_libdir}/scm
%{yast_desktopdir}/*.desktop

%dir %{yast_docdir}
%doc %{yast_docdir}/COPYING
%doc %{yast_docdir}/README.md
%doc %{yast_docdir}/CONTRIBUTING.md

%changelog
