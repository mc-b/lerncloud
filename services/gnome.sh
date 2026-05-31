#!/usr/bin/env bash
set -Eeuo pipefail

# =============================================================================
# Ubuntu Desktop Installation
#
# Installiert nur:
#   - Ubuntu GNOME Desktop
#   - Chromium
#   - PDF Reader
#   - Schweizer Tastatur-Layout Deutsch
# =============================================================================

log() {
  printf '\n[%s] %s\n' "$(date '+%F %T')" "$*"
}

die() {
  echo "FEHLER: $*" >&2
  exit 1
}

require_root() {
  [[ ${EUID:-$(id -u)} -eq 0 ]] || die "Bitte mit sudo oder als root ausfuehren."
}

install_desktop_packages() {
  log "Installiere Ubuntu GNOME Desktop, Chromium und PDF Reader"

  export DEBIAN_FRONTEND=noninteractive

  apt-get update

  apt-get install -y \
    ubuntu-gnome-desktop \
    ubuntu-gnome-wallpapers \
    gdm3 \
    dbus-x11 \
    xdg-utils \
    x11-xserver-utils \
    mesa-utils \
    fonts-dejavu \
    keyboard-configuration \
    console-setup \
    snapd \
    evince

  systemctl enable gdm3 || true

  # Chromium unter Ubuntu wird als Snap ausgeliefert.
  # Das ist bewusst direkt hier, kein First-Boot-Service.
  systemctl enable snapd.socket || true
  systemctl start snapd.socket || true
  systemctl start snapd.service || true

  if ! command -v chromium >/dev/null 2>&1 && ! command -v chromium-browser >/dev/null 2>&1; then
    snap install chromium
  else
    log "Chromium ist bereits installiert"
  fi
}

configure_keyboard_ch_de() {
  log "Konfiguriere Tastatur: Schweiz / Deutsch"

  export DEBIAN_FRONTEND=noninteractive

  mkdir -p /etc/default
  cat > /etc/default/keyboard <<'KBD'
XKBLAYOUT="ch"
XKBVARIANT="de"
XKBMODEL="pc105"
XKBOPTIONS=""
BACKSPACE="guess"
KBD

  echo 'keyboard-configuration keyboard-configuration/layoutcode string ch' | debconf-set-selections
  echo 'keyboard-configuration keyboard-configuration/variantcode string de' | debconf-set-selections
  echo 'keyboard-configuration keyboard-configuration/modelcode string pc105' | debconf-set-selections

  dpkg-reconfigure -f noninteractive keyboard-configuration || true
  setupcon || true

  # GNOME Tastatur-Layout systemweit vorgeben.
  mkdir -p /etc/dconf/profile /etc/dconf/db/local.d
  cat > /etc/dconf/profile/user <<'PROFILEEOF'
user-db:user
system-db:local
PROFILEEOF

  cat > /etc/dconf/db/local.d/00-keyboard <<'DCONFEOF'
[org/gnome/desktop/input-sources]
sources=[('xkb', 'ch+de'), ('xkb', 'ch')]
DCONFEOF

  dconf update || true
}

cleanup_apt() {
  log "Bereinige apt Cache"
  apt-get autoremove -y || true
  apt-get clean
  rm -rf /var/lib/apt/lists/*
}

require_root
install_desktop_packages
configure_keyboard_ch_de
cleanup_apt
log "Desktop, Chromium, PDF Reader und Schweizer Tastatur-Layout sind installiert"
