#!/usr/bin/env bash
#
# liefert die Public IP Adresse
#
set -u

get_public_ip() {
    local cloud_provider public_ip

    cloud_provider="$(cloud-init query v1.cloud_name 2>/dev/null || true)"

    case "$cloud_provider" in
        aws)
            public_ip="$(cloud-init query ds.meta_data.public_hostname 2>/dev/null || true)"
            ;;
        gce|gcloud)
            public_ip="$(
                curl -fsS \
                    -H 'Metadata-Flavor: Google' \
                    'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip' \
                    2>/dev/null || true
            )"
            ;;
        azure)
            public_ip="$(
                sed -n 's/.*"publicIpAddress"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
                    /run/cloud-init/instance-data.json 2>/dev/null \
                | head -n 1
            )"
            ;;
        maas)
            public_ip="$(hostname).maas"
            ;;
        multipass)
            public_ip="$(hostname).mshome.net"
            ;;
        *)
            public_ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
            ;;
    esac

    printf '%s\n' "$public_ip"
}

get_wg_ip() {
    ip -4 -o addr show 2>/dev/null \
      | awk '$2 ~ /^wg[0-9]+$/ { split($4,a,"/"); print a[1]; exit }'
}

get_default_ip() {
    ip -4 route get 1.1.1.1 2>/dev/null \
      | awk '{for (i=1; i<=NF; i++) if ($i=="src") { print $(i+1); exit }}'
}

main() {
    local wg_ip public_ip default_ip

    wg_ip="$(get_wg_ip)"
    [ -n "$wg_ip" ] && { printf '%s\n' "$wg_ip"; return; }

    public_ip="$(get_public_ip)"
    [ -n "$public_ip" ] && { printf '%s\n' "$public_ip"; return; }

    default_ip="$(get_default_ip)"
    printf '%s\n' "$default_ip"
}

main "$@"