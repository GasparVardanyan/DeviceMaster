#!/usr/bin/env bash

mkdir -p vendor
PERL5LIB=vendor cpanm --local-lib=vendor --installdeps .

pp \
	-I . \
	-I vendor/lib/perl5 \
	-I vendor/lib/perl5/x86_64-linux-thread-multi \
	-A vendor \
	-a vendor/lib/perl5 \
	-a vendor/lib/perl5/x86_64-linux-thread-multi \
	-M MooseX::Storage::Basic \
	-M MooseX::Storage::Format::JSON \
	-o DM DeviceMaster.pl
