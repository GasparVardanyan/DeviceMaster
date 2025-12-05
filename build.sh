#!/usr/bin/env bash

source /etc/profile

eval "$(perl -I vendor/lib/perl5 -Mlocal::lib=vendor)"
PERL5LIB=vendor cpanm --local-lib=vendor --installdeps .

pp \
	-c \
	-I . \
	-I vendor/lib/perl5 \
	-I vendor/lib/perl5/x86_64-linux-thread-multi \
	-A vendor \
	-a vendor/lib/perl5 \
	-a vendor/lib/perl5/x86_64-linux-thread-multi \
	-M MooseX::Storage::Basic \
	-M MooseX::Storage::Format::JSON \
	-o DM DeviceMaster.pl
