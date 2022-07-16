# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="IVPN UI Binary Package"
HOMEPAGE="https://www.ivpn.net"
SRC_URI="https://repo.ivpn.net/stable/pool/ivpn-ui_3.8.20_amd64.deb"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="net-vpn/ivpn-bin"
RDEPEND="${DEPEND}"
#BDEPEND=""

QA_PRESTRIPPED="/usr/bin/ivpn-ui"

src_unpack() {
	mkdir ${S} || die
	unpack ${A}
	unpack $WORKDIR/control.tar.gz
	unpack $WORKDIR/data.tar.gz
	cp -r $WORKDIR/* ${S}/
	mv ${S}/usr/share/doc/ivpn-ui ${S}/usr/share/doc/${PF}
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
echo "[*] After remove (3.8.20 : deb : $1)"

# Obtaining information about user running the script
# (script can be executed with 'sudo', but we should get real user)
USER="${SUDO_USER:-$USER}"
UI_APP_USER_DIR="/home/${USER}/.config/IVPN"
UI_APP_USER_DIR_OLD="/home/${USER}/.config/ivpn-ui" # (old productName='ivpn-ui')

AUTOSTART_FILE="/home/${USER}/.config/autostart/ivpn-ui.desktop"

DESKTOP_FILE_DIR=/usr/share/applications
DESKTOP_FILE=/usr/share/applications/IVPN.desktop

silent() {
  "$@" > /dev/null 2>&1
}

# STOPPING APPLICATION (same functionality implemented also in 'before-install.sh')
echo "[+] Checking for 'ivpn-ui' running processes ..."
ps aux | grep /opt/ivpn/ui/bin/ivpn-ui | grep -v grep  > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "[!] Detected: IVPN app is running"

  # We should be careful here: WE SHOULD NOT KILL THIS SCRIPT :)
  # (which also can have 'ivpn-ui' in process description)
  silent kill -TERM $(ps aux | grep /opt/ivpn/ui/bin/ivpn-ui | grep -v grep | awk '{print $2}')
  silent sleep 2
  silent kill -KILL $(ps aux | grep /opt/ivpn/ui/bin/ivpn-ui | grep -v grep | awk '{print $2}')
fi

# DEB argument on upgrade - 'upgrade'; RPM - '1'
if [ "$1" = "upgrade" ] || [ "$1" = "1" ] ; then
  # UPGRADE

  if [ -d $UI_APP_USER_DIR ] ; then
    echo "[!] Upgrade detected"
    echo "    Keeping application cache data from the previous version:"
    echo "    '$UI_APP_USER_DIR'"
  else
    # this is necessary for old application version (old productName='ivpn-ui')
    if [ -d $UI_APP_USER_DIR_OLD ] ; then
      echo "[!] Upgrade detected"
      echo "[+] Upgrading application old app version cache data ..."
      mv $UI_APP_USER_DIR_OLD $UI_APP_USER_DIR || echo "[-] Failed"
    fi
  fi

else
  # REMOVE
  if [ -d $DESKTOP_FILE_DIR ] ; then
    echo "[+] Uninstalling .desktop file: '$DESKTOP_FILE' ..."
    rm $DESKTOP_FILE || echo "[-] Failed"
  fi

  if [ -d $UI_APP_USER_DIR ] ; then
    echo "[+] Removing application cache data: '$UI_APP_USER_DIR' ..."
    rm -rf $UI_APP_USER_DIR || echo "[-] Failed"
  fi


  if [ -f $AUTOSTART_FILE ]; then
    echo "[+] Removing application autostart file: '$AUTOSTART_FILE' ..."
    rm $AUTOSTART_FILE || echo "[-] Failed"
  fi

fi

# removing old application version cache (old productName='ivpn-ui')
if [ -d $UI_APP_USER_DIR_OLD ] ; then
  echo "[+] Removing application cache data (old app version): '$UI_APP_USER_DIR_OLD' ..."
  rm -rf $UI_APP_USER_DIR_OLD || echo "[-] Failed"
fi
}
