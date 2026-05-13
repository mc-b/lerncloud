#!/usr/bin/env bash
set -euo pipefail

TS_AUTHKEY_ENC_B64='qTl6GNQWpSae5TnFk94kGy1Ccdyo3cC3dYDLD3pQVzXze2f/a+QCxs1kVkoTP8++jGWGT1tbHg9tihj42n4fXU4eWC09FTYsIX+MejMh4ccs7C9m09wiiywRDDrkUn0R77A03cyWSfoLMSXMBrwtd/loGyDsctq4mJpudUwOXkbMZEvqFeHYq32mEXuiXlzQMBxL1tVBZ5OlxJbIdTQjB4IiiQEW8Cr3/wfjhrpXk7j0ySObSU7GysegzF/F6PiYm3WrOCBA8/mh+CQhQb8rMbn8Hk+HXNf1jJPPgqBS8cVhlosfRdZJ/GrSDQvU5BW8sFjHrrOI0aZkqMG9jiO4bw=='
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_rsa}"
TS_HOSTNAME="${TS_HOSTNAME:-ts}"

[ -r "$SSH_KEY" ] || { echo "Fehler: SSH-Key nicht lesbar: $SSH_KEY" >&2; exit 0; }

TS_AUTHKEY="$(printf '%s' "$TS_AUTHKEY_ENC_B64" | base64 -d | openssl pkeyutl -decrypt -inkey "$SSH_KEY")"

[ -n "$TS_AUTHKEY" ] || { echo "Fehler: Authkey konnte nicht entschlüsselt werden" >&2; exit 0; }

curl -fsSL https://tailscale.com/install.sh | sh

sudo tailscale up --authkey="$TS_AUTHKEY" --hostname="$TS_HOSTNAME" --accept-routes=false --reset

unset TS_AUTHKEY