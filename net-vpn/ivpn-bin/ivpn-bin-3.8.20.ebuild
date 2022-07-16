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

pkg_prerm() {
PKG_TYPE=deb

echo "[+] Disabling firewall (before remove) ..."
/usr/bin/ivpn firewall -off || echo "[-] Failed to disable firewall"

echo "[+] Disconnecting (before remove) ..."
/usr/bin/ivpn disconnect || echo "[-] Failed to disconnect"

if [ "$PKG_TYPE" = "rpm" ]; then
    if [ -f /opt/ivpn/mutable/rpm_upgrade.lock ]; then
        echo "[ ] Upgrade detected. Remove operations skipped"
        exit 0
    fi
fi

if [ -f /opt/ivpn/mutable/settings.json ]; then
    # In case of installing new version, we have to login back with current logged-in accountID after installation finished.
    # Therefore we are saving accountID into temporary file (will be deleted after 'after_install' script execution)
    echo "[+] Preparing upgrade data ..."
    ACCID=$(cat /opt/ivpn/mutable/settings.json | grep -o \"AccountID\":\"[a-zA-Z0-9]*\" | cut -d '"' -f 4) || echo "[-] Failed to read accountID"
    if [ ! -z "$ACCID" ]; then
        echo $ACCID > /opt/ivpn/mutable/upgradeID.tmp || echo "[-] Failed to save accountID into temporary file"
    fi
fi

echo "[+] Logging out ..."
/usr/bin/ivpn logout || echo "[-] Failed to log out"

echo "[+] Service cleanup (pleaserun) ..."
sh /usr/share/pleaserun/ivpn-service/generate-cleanup.sh || echo "[-] Service cleanup FAILED!"
}

pkg_postrm() {
echo "[*] After remove (3.8.20 : deb : $1)"

PKG_TYPE=deb
if [ "$PKG_TYPE" = "rpm" ]; then
    if [ -f /opt/ivpn/mutable/rpm_upgrade.lock ]; then
        echo "[ ] Upgrade detected. Remove operations skipped"
        rm /opt/ivpn/mutable/rpm_upgrade.lock || echo "[-] Failed to remove rpm_upgrade.lock"
        exit 0
    fi
fi

silent() {
  "$@" > /dev/null 2>&1
}

has_systemd() {
  # Some OS vendors put systemd in ... different places ...
  [ -d "/lib/systemd/system/" -o -d "/usr/lib/systemd/system" ] && silent which systemctl
}

try_systemd_stop() {
    if has_systemd ; then
        echo "[ ] systemd detected. Trying to stop service ..."

        echo "[+] Stopping service"
        silent systemctl stop ivpn-service

        echo "[+] Disabling service"
        silent systemctl disable ivpn-service

        if [ -f "/etc/systemd/system/ivpn-service.service" ]; then
            echo "[+] Removing service"
            silent rm /etc/systemd/system/ivpn-service.service
        fi
        if [ -f "/usr/lib/systemd/system/ivpn-service.service" ]; then
            echo "[+] Removing service"
            silent rm /usr/lib/systemd/system/ivpn-service.service
        fi
    fi
}

FILE_ACCID_TO_UPGRADE="/opt/ivpn/mutable/toUpgradeID.tmp"
FILE_EAA_TO_UPGRADE="/opt/ivpn/mutable/eaa"
if [ -f $FILE_ACCID_TO_UPGRADE ]; then
  # It is an upgrade.
  # We need to re-login after installation finished.
  # Therefore we should not remove info about account ID.
  # Read into temporary variable
  ACCID=$(cat $FILE_ACCID_TO_UPGRADE) || echo "[-] Failed to read accountID to re-login"
  EAA=
fi

IVPN_DIR="/opt/ivpn"
IVPN_TMP="/opt/ivpn/mutable"
IVPN_LOG="/opt/ivpn/log"
IVPN_ETC="/opt/ivpn/etc"
if [ -d $IVPN_TMP ] ; then
  echo "[+] Removing other files ..."
  # Normally, all files which were installed, deleted automatically
  # But ivpn-service also writing to 'mutable' additional temporary files (uninstaller know nothing about them)
  # Therefore, we are completely removing all content of '/opt/ivpn/mutable'
  rm -rf $IVPN_TMP|| echo "[-] Removing '$IVPN_TMP' folder failed"
  rm -rf $IVPN_LOG|| echo "[-] Removing '$IVPN_LOG' folder failed"
  #rm -rf $IVPN_ETC|| echo "[-] Removing '$IVPN_ETC' folder failed"
  #rm -rf $IVPN_DIR|| echo "[-] Removing '$IVPN_DIR' folder failed"
  #remove 'ivpn' folder (if empy)
  silent sudo rmdir $IVPN_DIR
fi

if [ ! -z "$ACCID" ]; then
  # It is an upgrade.
  # We need to re-login after installation finished.
  # Therefore we should not remove info about account ID
  # Save to a file from temporary variable
    DIR=$(dirname $FILE_ACCID_TO_UPGRADE) || echo "[-] Failed to save accountID to re-login (1)"
    mkdir -p $DIR                         || echo "[-] Failed to save accountID to re-login (2)"
    echo $ACCID > $FILE_ACCID_TO_UPGRADE  || echo "[-] Failed to save accountID to re-login (3)"
  fi

IVPN_SAVED_DNS_FILE="/etc/resolv.conf.ivpnsave"
if [ -f $IVPN_SAVED_DNS_FILE ]; then
  echo "[+] restoring DNS configuration"
  mv $IVPN_SAVED_DNS_FILE /etc/resolv.conf || echo "[-] Restoring DNS failed"
fi

try_systemd_stop

# cleanup other files
if [ -d "/usr/share/pleaserun" ]; then rm -rf /usr/share/pleaserun; fi
if [ -e "/etc/init.d/ivpn-service" ]; then rm -rf /etc/init.d/ivpn-service; fi
}
