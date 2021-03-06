# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="IVPN Binary Package"
HOMEPAGE="https://www.ivpn.net"
SRC_URI="https://repo.ivpn.net/stable/pool/ivpn_3.8.20_amd64.deb"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="net-vpn/openvpn
	net-vpn/wireguard-tools"
RDEPEND="${DEPEND}"
#BDEPEND=""

QA_PRESTRIPPED="/usr/bin/ivpn
	/opt/ivpn/obfsproxy/obfs4proxy
	/opt/ivpn/dnscrypt-proxy/dnscrypt-proxy"

src_unpack() {
	mkdir ${S} || die
	unpack ${A}
	unpack $WORKDIR/control.tar.gz
	unpack $WORKDIR/data.tar.gz
	cp -r $WORKDIR/* ${S}/
	mv ${S}/usr/share/doc/ivpn ${S}/usr/share/doc/${PF}
	gunzip ${S}/usr/share/doc/${PF}/changelog.gz
}

src_install() {
	cp -r "${S}/usr" "${D}/" || die
	cp -r "${S}/opt" "${D}/" || die
}

pkg_preinst() {
	sh ${S}/preinst
}

pkg_postinst() {
	sh ${S}/postinst
}

pkg_postrm() {
	[[ -f "$ROOT/usr/bin/ivpn-service" ]] || rm /etc/init.d/ivpn-service
	[ -f "$ROOT/usr/bin/ivpn-service" ] || { systemctl disable ivpn-service.service; rm /etc/systemd/system/ivpn-service.service; }
	[[ -f "$ROOT/usr/bin/ivpn-service" ]] || rm -rf /usr/share/pleaserun
	[[ -f "$ROOT/usr/bin/ivpn" ]] || rm -rf /opt/ivpn
}