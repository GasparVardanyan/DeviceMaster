#!/usr/bin/env bash

mkdir vendor
PERL5LIB=vendor cpanm --local-lib=vendor --installdeps .

/usr/bin/vendor_perl/pp \
	-I . \
	-I vendor/lib/perl5 \
	-A vendor \
	-a vendor/lib/perl5 \
	-M MooseX::Storage::Basic \
	-M MooseX::Storage::Format::JSON \
	-o DM DeviceMaster.pl
