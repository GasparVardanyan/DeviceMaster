pkgname=devicemaster
pkgver=r12.16bfe56
pkgrel=1
arch=('x86_64')
depends=('perl')
makedepends=('perl' 'perl-par-packer' 'cpanminus' 'perl-local-lib')
options=('!strip')
source=('devicemaster::git+https://github.com/GasparVardanyan/DeviceMaster')
sha256sums=('SKIP')

pkgver() {
	cd "$srcdir/$pkgname"
	printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

prepare() {
	cd "$srcdir/$pkgname"

	source /etc/profile

	eval "$(perl -I vendor/lib/perl5 -Mlocal::lib=vendor)"
	PERL5LIB=vendor cpanm --local-lib=vendor --installdeps .
}

build() {
	cd "$srcdir/$pkgname"

	source /etc/profile

	eval "$(perl -I vendor/lib/perl5 -Mlocal::lib=vendor)"

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
}

package() {
	install -Dm755 "$srcdir/$pkgname/DM" "$pkgdir/usr/bin/devicemaster"
	install -Dm644 "$srcdir/$pkgname/LICENSE" "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
