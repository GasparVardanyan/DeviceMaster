#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Find;

my %pm;

find(
	sub {
		return unless /\.pm$/;
		my $src = $File::Find::name;

		# Strip leading "lib/"
		(my $dest = $src) =~ s{^lib/}{};

		$pm{$src} = "\$(INST_LIBDIR)/$dest";
	},
	'lib'
);

WriteMakefile(
	NAME         => 'DeviceMaster',
	VERSION      => '0.01',
	EXE_FILES    => ['bin/DeviceMaster.pl'],
	PM           => \%pm,
	INSTALLDIRS  => 'site',
);
