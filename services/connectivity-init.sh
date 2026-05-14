#!/usr/bin/env bash
set -euo pipefail

TS_AUTHKEY_ENC_B64='0W7cUWzSHUsJyctx6PXnZzH97fM08fXFnl6O2W5pZBnF0jHA9TVhqAPoDpzSGxPDvzNs7jc++kqhQRpI3AXsrrEjMwjsPJVKn3TPPtFLAz3lB61GdiZKDzyiMv6Mr3rMEX3FGakT97/44R7cmmBuzsZYlzPh+MNz/vt3P7Nky9gg8saCxts5A9d49m1x8325grHTetgDe38Dp1cVyUGV27B81mI7VGWIAQhDma0XnW4sOs3XxmHLuMI7LHHFq/j8fkTLwm6rz7W/v7txFKREePGNoprLl6vaSUM3/mBKZ/FEo8Zi1+4+JD3bVZHr+bD8LGZEO35sAvnybP2dUIqTMQ=='
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_rsa}"

PUBLIC_IP_PART="$(curl -s ifconfig.me | cut -d. -f1)"

if [ -f "$HOME/data/server-ip" ]; then
  SERVER_IP_SUFFIX="$(tr '.' '-' < "$HOME/data/server-ip" | tr -d '[:space:]')"
  SERVER_IP_SUFFIX="-$SERVER_IP_SUFFIX"
else
  SERVER_IP_SUFFIX=""
fi

TS_HOSTNAME="${TS_HOSTNAME:-duk}-${PUBLIC_IP_PART}${SERVER_IP_SUFFIX}"

[ -r "$SSH_KEY" ] || { echo "Fehler: SSH-Key nicht lesbar: $SSH_KEY" >&2; exit 0; }

TS_AUTHKEY="$(printf '%s' "$TS_AUTHKEY_ENC_B64" | base64 -d | openssl pkeyutl -decrypt -inkey "$SSH_KEY")"

[ -n "$TS_AUTHKEY" ] || { echo "Fehler: Authkey konnte nicht entschlüsselt werden" >&2; exit 0; }

curl -fsSL https://tailscale.com/install.sh | sh

sudo tailscale up --authkey="$TS_AUTHKEY" --hostname="$TS_HOSTNAME" --accept-routes=false --reset

unset TS_AUTHKEY