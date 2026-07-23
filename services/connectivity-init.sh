#!/usr/bin/env bash
set -euo pipefail

PUBLIC_IP_PART="$(curl -s -4 ifconfig.me | cut -d. -f1)"

get_hostname() {
    local cloud_provider public_ip

    cloud_provider="$(cloud-init query v1.cloud_name 2>/dev/null || true)"

    case "$cloud_provider" in
        "aws" | "azure" | "gcloud")
            public_ip="${TS_HOSTNAME}-$(sudo cloud-init query ds.meta_data.public_hostname)"
            ;;
        "maas")
            public_ip="${TS_HOSTNAME}-$(hostname).maas-${PUBLIC_IP_PART}"
            ;;
        "multipass")
            public_ip="${TS_HOSTNAME}.mshome.net-${PUBLIC_IP_PART}"
            ;;
        *)
            public_ip="$(hostname 2>/dev/null)-${PUBLIC_IP_PART}"
            ;;
    esac

    printf '%s\n' "$public_ip"
}
TS_HOSTNAME=$(get_hostname)

# tag:lerncloud Network
TS_AUTHKEY_ENC_B64='s4xrzpLzczXaeGhssHdIcm3vpS2joRW7MrJpFHd50z+vzEG7mK8yP4Cy1fwtM92lJrZLx4q+k9i0L7ujjai/apbB6XI4SpEIPPFaLfNhA6t/qZVWRRYSrjoio6VFXuAM+SZt7MqN/nFLcAqvOiStQ2p6VWY7hJ8FfQmIletJTU53sba4R8XfX4Fy4JyStFOwFVKgIqQHC3UCdMRb/+ofXpq+wirYjNw9o/ucXpq07kagXh5ujaePQYF+2y59B29sxakinfwnRSucqmDhBHj8tZOid5p7F8xQo2IU3H5tP9iBzSj9bIoAcmYBpvacoQM2vqYUzaGhHqyj0/995n4tdA=='
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_rsa}"

[ -r "$SSH_KEY" ] || { echo "Fehler: SSH-Key nicht lesbar: $SSH_KEY" >&2; exit 0; }

TS_AUTHKEY="$(printf '%s' "$TS_AUTHKEY_ENC_B64" | base64 -d | openssl pkeyutl -decrypt -inkey "$SSH_KEY")"

[ -n "$TS_AUTHKEY" ] || { echo "Fehler: Authkey konnte nicht entschlüsselt werden" >&2; exit 0; }

curl -fsSL https://tailscale.com/install.sh | sh

sudo tailscale up --authkey="$TS_AUTHKEY" --hostname="$TS_HOSTNAME" --accept-routes=false --reset --advertise-tags=tag:lerncloud

unset TS_AUTHKEY



