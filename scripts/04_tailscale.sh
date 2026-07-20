#!/bin/bash
# Phase 4: Tailscale installieren und anmelden. Der Browser-Login passiert
# bewusst manuell (siehe Runbook).
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"

require_root

if ! command -v tailscale &>/dev/null; then
    log "Tailscale installieren (offizielles Install-Skript) ..."
    curl -fsSL https://tailscale.com/install.sh | sh
else
    log "Tailscale ist bereits installiert — übersprungen."
fi

systemctl enable --now tailscaled

log "Jetzt erscheint eine Login-URL. Diese am Mac im Browser öffnen und"
log "mit dem Tailscale-Account anmelden (siehe handbuch/tailscale.md)."
# --accept-dns=false: dieses VPS wird selbst der DNS-Server des Tailnets
tailscale up --accept-dns=false

success "Tailscale verbunden. Die Tailscale-IP dieses Servers:"
tailscale ip -4
log "Weiter im Runbook: SSH über diese IP testen, DANN erst Phase 5 (Lockdown)."
