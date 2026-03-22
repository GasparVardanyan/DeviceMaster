#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker ();
use File::Find ();

ExtUtils::MakeMaker::WriteMakefile (
	NAME         => 'DeviceMaster',
	VERSION      => '1.3.3.7',
	EXE_FILES    => ['bin/DeviceMaster.pl'],
	PM           => do {
		my %pm;

		File::Find::find (
			sub {
				return unless /\.pm$/;
				my $src = $File::Find::name;

				(my $dest = $src) =~ s{^lib/}{};

				$pm{$src} = "\$(INST_LIBDIR)/$dest";
			},
			'lib'
		);

		\%pm;
	},
	INSTALLDIRS  => 'vendor',
);
