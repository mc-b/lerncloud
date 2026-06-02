#!/bin/bash
#
#   Richtet Linux UI (XFCE + XRDP) ein
#
#   Usage:
#     sudo ./install-linux-ui.sh [USERNAME]
#
set +e  # Fehler ignorieren

USERNAME="${1:-${USERNAME}}"
HOME_DIR=$(eval echo "~$USERNAME")
DEFAULT_TARGET="${DEFAULT_TARGET:-multi-user}"

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
  xserver-xorg-core \
  xserver-xorg-input-all \
  xfce4 \
  xfce4-goodies \
  xrdp \
  dbus-x11 \
  lightdm \
  lightdm-gtk-greeter \
  evince \
  chromium || echo "⚠️ [WARN] Paketinstallation teilweise fehlgeschlagen"

###########################################################
# XRDP auf Xorg umstellen (wichtig für ${USERNAME} 24.04)
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
cat > "${HOME_DIR}/.xsession" <<'EOF'
#!/bin/sh
unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR
exec startxfce4
EOF

chmod +x "${HOME_DIR}/.xsession"
chown "${USERNAME}:${USERNAME}" "${HOME_DIR}/.xsession" || echo "⚠️ [WARN] Konnte Besitzer von .xsession nicht setzen"

# Für console -> login -> startx
cat > /home/${USERNAME}/.xinitrc <<'EOF'
exec startxfce4
EOF

# Für GUI login
chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.xinitrc
chmod +x /home/${USERNAME}/.xinitrc

mkdir -p /var/lib/AccountsService/users

cat > /var/lib/AccountsService/users/${USERNAME} <<'EOF'
[User]
Session=xfce
XSession=xfce
SystemAccount=false
EOF


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

###########################################################
# Setze Tastaturlayout auf CH (Swiss)
###########################################################

echo "⌨️ [INFO] Configure Swiss keyboard layout (CH) for TTY, X11 and XRDP"

# ------------------------------------------------------------
# 0. Cleanup previous broken configs (IMPORTANT)
# ------------------------------------------------------------
rm -f /etc/xdg/autostart/*keyboard*
rm -f /etc/X11/xorg.conf.d/*keyboard*.conf

# ------------------------------------------------------------
# 1. Console / TTY keyboard (works for ASCII console)
# ------------------------------------------------------------
cat <<EOF > /etc/default/keyboard
XKBMODEL="pc105"
XKBLAYOUT="ch"
XKBVARIANT=""
XKBOPTIONS=""
EOF

dpkg-reconfigure -f noninteractive keyboard-configuration || true
systemctl restart keyboard-setup || true

# ------------------------------------------------------------
# 2. XRDP login keyboard (BEFORE password entry)
# ------------------------------------------------------------
XRDP_INI="/etc/xrdp/xrdp.ini"

if grep -q "^\[Globals\]" "$XRDP_INI"; then
    sed -i '/^\[Globals\]/a keyboard_layout=ch\nkeyboard_type=pc105' "$XRDP_INI"
else
    echo "[Globals]" >> "$XRDP_INI"
    echo "keyboard_layout=ch" >> "$XRDP_INI"
    echo "keyboard_type=pc105" >> "$XRDP_INI"
fi

# ------------------------------------------------------------
# 3. Xorg fallback (GUI after login)
# ------------------------------------------------------------
mkdir -p /etc/X11/xorg.conf.d
cat <<EOF > /etc/X11/xorg.conf.d/00-keyboard.conf
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "ch"
EndSection
EOF

# ------------------------------------------------------------
# Background setzen
# ------------------------------------------------------------
sudo wget -S https://raw.githubusercontent.com/mc-b/lerncloud/main/images/xfce4-background.svg -O /usr/share/backgrounds/xfce/xfce-shapes.svg

# ------------------------------------------------------------
# 4. Restart XRDP stack
# ------------------------------------------------------------
systemctl stop xrdp
systemctl stop xrdp-sesman
sleep 5
systemctl start xrdp
systemctl start xrdp-sesman

echo "✅ [OK] Keyboard layout CH applied safely"

# ------------------------------------------------------------
# GUI-Autostart 
# ------------------------------------------------------------

# unnoetige Display Manager (Gnome + KDE) stoppen & deaktivieren (falls vorhanden)
for dm in gdm3 sddm; do
    if systemctl list-unit-files | grep -q "^$dm"; then
        systemctl disable --now "$dm" || true
    fi
done


case "$DEFAULT_TARGET" in
  multi-user)
    echo "🛑 [INFO] Boot to console, start GUI manually with startx"
    systemctl set-default multi-user.target
    systemctl disable --now lightdm 2>/dev/null || true
    ;;

  graphical)
    echo "🖥️ [INFO] Boot to graphical login with LightDM"
    systemctl set-default graphical.target
    systemctl daemon-reload
    systemctl enable lightdm
    # sofort starten, ohne Reboot
    systemctl restart lightdm || systemctl start lightdm
    ;;
  *)
    echo "FEHLER: Ungueltiger DEFAULT_TARGET: $DEFAULT_TARGET"
    echo "Erlaubt: graphical, multi-user"
    exit 1
    ;;
esac

echo ""
echo "✅ [INFO] Linux UI Installation & Configuration Complete (XFCE + XRDP)"
echo "   - Desktop: XFCE4"
echo "   - Remote:  XRDP (Xorg)"
echo "   - User:    ${USERNAME}"
