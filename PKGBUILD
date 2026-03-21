pkgname=devicemaster
pkgver=r33.328921a
pkgrel=1
pkgdesc='device management utility for linux'
arch=('x86_64')
depends=(
	'perl'
	'perl-namespace-autoclean'
	'perl-moo'
	'perl-type-tiny'
	'perl-json-xs'
)
license=('custom')
options=('!emptydirs' '!debug')
# for personal tests:
# source=('devicemaster::git+file:///src/repos/DeviceMaster.git#branch=gaspar')
source=('devicemaster::git+https://github.com/GasparVardanyan/DeviceMaster')
sha256sums=('SKIP')

pkgver() {
	cd "$srcdir/$pkgname"
	printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

build() {
	cd $pkgname

	(
		# https://github.com/BlackArch/blackarch-pkgbuilds/blob/master/PKGBUILD-perl-lib
		export PERL_MM_USE_DEFAULT=1 PERL5LIB="" PERL_AUTOINSTALL=--skipdeps \
		PERL_MM_OPT="INSTALLDIRS=vendor DESTDIR='$pkgdir'" \
		PERL_MB_OPT="--installdirs vendor --destdir '$pkgdir'" \
		MODULEBUILDRC=/dev/null

		/usr/bin/perl Makefile.PL

		make
	)
}

package() {
	cd $pkgname
	install -Dm644 "$srcdir/$pkgname/LICENSE" "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
	make DESTDIR="$pkgdir" install
}
