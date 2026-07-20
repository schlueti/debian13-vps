#!/bin/bash
# Phase 5: Firewall aktivieren. Danach ist der Server von außen dicht —
# SSH und alle Dienste nur noch über Tailscale.
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"

require_root

if ! tailscale status &>/dev/null; then
    error "Tailscale ist nicht verbunden — Abbruch. Erst Phase 4 abschließen."
    exit 1
fi

TS_IP="$(tailscale ip -4)"
echo
log "Tailscale-IP dieses Servers: $TS_IP"
log "SICHERHEITS-CHECK: Öffne JETZT ein zweites Terminal am Mac und teste:"
log "    ssh ${SUDO_USER:-christina}@$TS_IP"
log "Dieses Fenster dabei OFFEN lassen."
echo
read -rp "Funktioniert der SSH-Login über die Tailscale-IP? (ja/nein) " answer
if [ "$answer" != "ja" ]; then
    error "Abbruch. Erst muss SSH über Tailscale laufen — sonst sperrst du dich aus."
    exit 1
fi

log "Firewall-Regeln setzen ..."
ufw default deny incoming
ufw default allow outgoing
ufw allow in on tailscale0 comment 'Tailscale-Netz'
ufw allow 41641/udp comment 'Tailscale direkte Verbindungen'
ufw --force enable
ufw status verbose

success "Phase 5 fertig. Der Server ist von außen dicht — Zugriff nur noch über Tailscale."
