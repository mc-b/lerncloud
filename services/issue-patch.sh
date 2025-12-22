#!/bin/bash
#   
#   /etc/issue - mit IP Adresse
#
set +e  # Fehler ignorieren

#!/bin/bash

echo "📡 [INFO] Setup: IP-Adresse & OS vor Login anzeigen"

# -------------------------------
# 1. Script zum Erzeugen von /etc/issue
# -------------------------------
cat <<'EOF' > /usr/local/bin/update-issue-ip.sh
#!/bin/bash

# OS-Name dynamisch ermitteln
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS="$PRETTY_NAME"
else
    OS="$(uname -s)"
fi

# Hostname
HOST=$(hostname)

# Primäre IPv4 ermitteln
IP=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7}')

cat <<EOT > /etc/issue
========================================
 $OS
 Hostname : $HOST
 IP Address: ${IP:-no network}
========================================

EOT
EOF

chmod +x /usr/local/bin/update-issue-ip.sh

# -------------------------------
# 2. systemd Service (läuft vor Login)
# -------------------------------
cat <<EOF > /etc/systemd/system/update-issue-ip.service
[Unit]
Description=Update /etc/issue with OS and IP
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/update-issue-ip.sh

[Install]
WantedBy=multi-user.target
EOF

# -------------------------------
# 3. Aktivieren
# -------------------------------
systemctl daemon-reload
systemctl enable update-issue-ip.service
systemctl start update-issue-ip.service

echo "✅ [OK] IP & OS werden nun vor dem Login angezeigt"
echo "ℹ️  Sichtbar auf TTY / VM / Server-Konsole"
