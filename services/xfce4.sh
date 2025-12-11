#!/bin/bash
#
#   Richtet Linux UI (XFCE + XRDP) ein
#
#   Usage:
#     sudo ./install-linux-ui.sh [USERNAME]
#
set +e  # Fehler ignorieren

USERNAME="${1:-ubuntu}"
HOME_DIR=$(eval echo "~$USERNAME")

echo "🚀 [INFO] Installing Linux UI (XFCE + XRDP) for user: ${USERNAME}"

if [ "$EUID" -ne 0 ]; then
  echo "❌ [ERROR] Dieses Script muss als root ausgeführt werden (sudo)."
  exit 1
fi

echo "- 🔄 [INFO] apt update"
apt-get update -y

echo "- 📦 [INFO] Installing UI-related packages (Xorg, XFCE, XRDP, Browser, Polkit)"
apt-get install -y \
  xorg \
  xfce4 \
  xfce4-goodies \
  xrdp \
  policykit-1 \
  policykit-1-gnome \
  firefox \
  chromium || echo "⚠️ [WARN] Paketinstallation teilweise fehlgeschlagen"

###########################################################
# XRDP auf Xorg umstellen (wichtig für Ubuntu 24.04)
###########################################################
echo "- ⚙️ [INFO] Configuring XRDP to use Xorg"

if [ -f /etc/X11/Xwrapper.config ]; then
  sed -i 's/console/anybody/g' /etc/X11/Xwrapper.config || echo "⚠️ [WARN] Konnte /etc/X11/Xwrapper.config nicht anpassen"
else
  echo "⚠️ [WARN] /etc/X11/Xwrapper.config nicht gefunden – wird übersprungen"
fi

if [ -f /etc/xrdp/sesman.ini ]; then
  sed -i 's/^param=.*Xvnc/param=sesman-Xorg/g' /etc/xrdp/sesman.ini || echo "⚠️ [WARN] Konnte /etc/xrdp/sesman.ini nicht anpassen"
else
  echo "⚠️ [WARN] /etc/xrdp/sesman.ini nicht gefunden – wird übersprungen"
fi

echo "- 🔁 [INFO] Restarting & enabling xrdp"
systemctl restart xrdp || echo "⚠️ [WARN] Konnte xrdp nicht neu starten"
systemctl enable xrdp || echo "⚠️ [WARN] Konnte xrdp nicht aktivieren (enable)"

###########################################################
# XFCE für XRDP aktivieren
###########################################################
echo "- 🖥️ [INFO] Setting XFCE as default session for XRDP"

mkdir -p "${HOME_DIR}"
echo "xfce4-session" > "${HOME_DIR}/.xsession"
chown "${USERNAME}:${USERNAME}" "${HOME_DIR}/.xsession" || echo "⚠️ [WARN] Konnte Besitzer von .xsession nicht setzen"

###########################################################
# Polkit Agent für XRDP (verhindert Logout-Loop)
###########################################################
echo "- 🔐 [INFO] Enabling Polkit agent autostart for XRDP"

mkdir -p "${HOME_DIR}/.config/autostart"
if [ -f /usr/share/applications/polkit-gnome-authentication-agent-1.desktop ]; then
  cp /usr/share/applications/polkit-gnome-authentication-agent-1.desktop \
     "${HOME_DIR}/.config/autostart/" || echo "⚠️ [WARN] Konnte Polkit-Desktop-File nicht kopieren"
else
  echo "⚠️ [WARN] Polkit-Desktop-File nicht gefunden – wird übersprungen"
fi
chown -R "${USERNAME}:${USERNAME}" "${HOME_DIR}/.config" || echo "⚠️ [WARN] Konnte Besitzer von .config nicht setzen"

echo ""
echo "✅ [INFO] Linux UI Installation & Configuration Complete (XFCE + XRDP)"
echo "   - Desktop: XFCE4"
echo "   - Remote:  XRDP (Xorg)"
echo "   - User:    ${USERNAME}"
