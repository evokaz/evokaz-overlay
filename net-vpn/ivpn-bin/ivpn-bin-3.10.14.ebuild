# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="IVPN Binary Package"
HOMEPAGE="https://www.ivpn.net"
SRC_URI="https://repo.ivpn.net/stable/pool/ivpn_${PV}_amd64.deb"

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
	if [[ -d "$ROOT/etc/systemd" ]]; then
		elog "Systemd found: Restarting Services"
		systemctl stop ivpn-service.service
		systemctl start ivpn-service.service
	else
		elog "OpenRC init system found: Restarting Services"
		rc-service ivpn-service stop
		rc-service ivpn-service start
	fi

	einfo "Remember to enable the service at desired runlevel:"
	einfo "- Systemd: systemctl enable ivpn-service.service"
	einfo "- OpenRC: rc-update add ivpn-service default"
}

pkg_postrm() {
	if [[ -f "$ROOT/usr/bin/ivpn-service" ]]; then
		elog "IVPN Service found, may be an upgrade. Doing nothing."
	else
		elog "IVPN Service uninstalled. Cleaning files..."
		
		if [[ -f "$ROOT/etc/systemd/system/ivpn-service.service" ]]; then
			elog "Systemd found. Disabling and removing service..."
			systemctl stop ivpn-service.service
			systemctl disable ivpn-service.service
			rm /etc/systemd/system/ivpn-service.service
		fi

		if [[ -f "$ROOT/etc/init.d/ivpn-service" ]]; then
			elog "OpenRC found. Disabling and removing service..."
			rc-service ivpn-service stop
			rc-update del ivpn-service
			rm /etc/init.d/ivpn-service
		fi

		rm -rf /usr/share/pleaserun
		rm -rf /opt/ivpn
	fi
}
