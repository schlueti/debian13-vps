#!/bin/bash
# Phase 3: Docker aus dem offiziellen Repo + Daemon-Härtung (Log-Limits,
# no-new-privileges, live-restore).
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"

USERS=(christina markus)
require_root
require_debian13

if ! command -v docker &>/dev/null; then
    log "Docker-Repository einrichten ..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    # shellcheck disable=SC1091
    . /etc/os-release
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $VERSION_CODENAME stable" \
        > /etc/apt/sources.list.d/docker.list
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        docker-ce docker-ce-cli containerd.io docker-compose-plugin
else
    log "Docker ist bereits installiert — übersprungen."
fi

log "Docker-Daemon härten (Log-Limits, no-new-privileges, live-restore) ..."
# Achtung: no-new-privileges gilt hier host-weit für ALLE Container und kann
# nicht pro Container per security_opt übersteuert werden (moby#45311).
# Braucht ein Container später setuid/file-capabilities, muss DIESE Datei ran.
cat > /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" },
  "live-restore": true,
  "no-new-privileges": true
}
EOF
systemctl enable --now docker
systemctl restart docker

for u in "${USERS[@]}"; do
    usermod -aG docker "$u"
done

success "Phase 3 fertig. Neu einloggen, damit die docker-Gruppe greift — dann: docker ps"
