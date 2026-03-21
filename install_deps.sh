#!/usr/bin/env bash

source /etc/profile

eval "$(perl -I vendor/lib/perl5 -Mlocal::lib=vendor)"
PERL5LIB=vendor cpanm --local-lib=vendor --installdeps .
