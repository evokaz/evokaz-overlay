# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Obsidian is a powerful knowledge base on top of a local folder of plain text Markdown files. "
HOMEPAGE="https://obsidian.md"
SRC_URI="https://github.com/obsidianmd/obsidian-releases/releases/download/v1.1.9/obsidian_1.1.9_amd64.deb"

LICENSE="EULA"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="x11-libs/gtk+:3
	x11-base/xorg-server
	app-crypt/libsecret
	x11-misc/xdg-utils"
RDEPEND="${DEPEND}"
BDEPEND=""

inherit xdg-utils

src_unpack() {
	mkdir ${S} || die
	unpack ${A}
	unpack $WORKDIR/control.tar.gz
	unpack $WORKDIR/data.tar.xz
	mv $WORKDIR/* ${S}/
	mv ${S}/usr/share/doc/obsidian ${S}/usr/share/doc/${PF}
	gunzip ${S}/usr/share/doc/${PF}/changelog.gz
}

src_install() {
	cp -r "${S}/usr" "${D}/" || die
	cp -r "${S}/opt" "${D}/" || die
}

pkg_postinst() {
	sh ${S}/postinst
	xdg_icon_cache_update
}

pkg_postrm() {
	[[ -f "$ROOT/opt/Obsidian" ]] || rm /usr/bin/obsidian
	xdg_icon_cache_update
}