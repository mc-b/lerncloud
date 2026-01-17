#!/bin/sh
set -eu

# Root-Check
if [ "$(id -u)" -ne 0 ]; then
  echo "Dieses Script muss als root ausgeführt werden" >&2
  exit 1
fi

# Abhängigkeit prüfen
if ! command -v efibootmgr >/dev/null 2>&1; then
  echo "efibootmgr ist nicht installiert" >&2
  exit 1
fi

echo "Aktuelle UEFI Boot-Einträge:"
efibootmgr
echo

# PXE / Netzwerk Boot-Einträge ermitteln
PXE_IDS=$(efibootmgr \
  | grep -Ei 'PXE|IPv4|IPv6|Network' \
  | sed -n 's/^Boot\([0-9A-F]\+\).*/\1/p')

if [ -z "${PXE_IDS}" ]; then
  echo "Keine PXE/Netzwerk-Boot-Einträge gefunden"
  exit 0
fi

for id in ${PXE_IDS}; do
  echo "Entferne PXE Boot-Eintrag: Boot${id}"
  efibootmgr -b "${id}" -B
done

echo
echo "Boot-Einträge nach Bereinigung:"
efibootmgr
