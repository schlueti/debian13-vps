#!/bin/bash
# Phase 6 (Vorbereitung): Host-DNS für Pi-hole freiräumen.
# Debian 13 belegt Port 53 mit dem systemd-resolved-Stub-Listener — dann kann
# der Pi-hole-Container nicht auf :53 binden. Wir schalten NUR den Stub-Listener
# ab (resolved bleibt als lokaler Resolver aktiv) und geben dem Host selbst
# einen festen Upstream, damit die Kiste beim Boot nicht von Pi-hole abhängt
# (Henne-Ei: Pi-hole braucht DNS, um zu starten).
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"

require_root
require_debian13

log "systemd-resolved Stub-Listener auf :53 abschalten ..."
mkdir -p /etc/systemd/resolved.conf.d
cat > /etc/systemd/resolved.conf.d/pihole.conf <<'EOF'
[Resolve]
# Stub-Listener aus, sonst kollidiert resolved mit dem Pi-hole-Container auf :53
DNSStubListener=no
# Fester Upstream für den Host selbst — unabhängig von Pi-hole (Boot-Henne-Ei)
DNS=9.9.9.9
EOF
systemctl restart systemd-resolved

log "/etc/resolv.conf auf resolved zeigen lassen ..."
# resolved pflegt hier seinen Upstream; als echte Symlink-Datei überlebt das
# Reboots, ohne dass wir eine statische Datei von Hand pflegen müssen.
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

if ss -H -lun 'sport = :53' | grep -q .; then
    error "Port 53/udp ist noch belegt — 'ss -lunp sport = :53' prüfen, bevor Pi-hole startet."
    exit 1
fi

success "Phase 6 vorbereitet: Port 53 frei. Weiter im Runbook: Stacks kopieren, docker compose up -d."
