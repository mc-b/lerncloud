#!/bin/bash
#
#   Installiert GitLab CE minimal für UI/Git
#   Ohne Monitoring, Registry, Pages, Mattermost, KAS
#   Als root starten / cloud-init geeignet
#

set +e  # Fehler ignorieren

echo "🚀 [INFO] Starte GitLab CE Installation..."

SERVER_IP_FILE="/home/ubuntu/data/server-ip"
GITLAB_PORT="9999"

if [ -f "$SERVER_IP_FILE" ]; then
  SERVER_IP="$(cat "$SERVER_IP_FILE")"
else
  SERVER_IP="$(hostname -I | awk '{print $1}')"
fi

EXTERNAL_URL="http://${SERVER_IP}:${GITLAB_PORT}"

echo "🌍 [INFO] GitLab URL: $EXTERNAL_URL"

echo "- 🔧 [INFO] Basis-Pakete installieren"
apt-get update
apt-get install -y curl ca-certificates openssh-server tzdata perl

echo "- 🔧 [INFO] GitLab Repository einrichten"
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | os=ubuntu dist=noble bash -

echo "- 📦 [INFO] GitLab CE installieren"
apt-get install -y gitlab-ce

echo "- ⚙️ [INFO] GitLab minimal konfigurieren"
tee /etc/gitlab/gitlab.rb > /dev/null <<EOF
external_url '${EXTERNAL_URL}'

nginx['listen_port'] = ${GITLAB_PORT}
nginx['listen_https'] = false

# Monitoring deaktivieren
prometheus_monitoring['enable'] = false
prometheus['enable'] = false
alertmanager['enable'] = false

node_exporter['enable'] = false
redis_exporter['enable'] = false
postgres_exporter['enable'] = false
gitlab_exporter['enable'] = false

# Nicht benötigte Komponenten deaktivieren
gitlab_pages['enable'] = false
registry['enable'] = false
gitlab_kas['enable'] = false
EOF

echo "- 🔄 [INFO] GitLab reconfigure ausführen"
gitlab-ctl reconfigure

echo "- 🔁 [INFO] GitLab neu starten"
gitlab-ctl restart

echo "- 🔐 [INFO] Initiales root Passwort:"
cat /etc/gitlab/initial_root_password 2>/dev/null | grep Password || true

echo "- 🌐 [INFO] Offene GitLab Ports:"
ss -tulpn | grep gitlab || true

echo "✅ [INFO] GitLab CE wurde installiert!"
echo "➡️  URL: ${EXTERNAL_URL}"
echo "➡️  Login: root"