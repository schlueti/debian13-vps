#!/bin/bash
# Nächtliches Backup — wird von christina-backup.timer um 04:00 aufgerufen.
# Läuft als root. Sichert nach /srv/backups (synct später Syncthing zur NAS).
set -Eeuo pipefail

BACKUP_DIR=/srv/backups
STACKS_DIR=/opt/setup/stacks
KEEP_DAYS=14
DATE="$(date +%F)"

mkdir -p "$BACKUP_DIR"
echo "[$(date '+%F %T')] Backup startet"

# 1) Vaultwarden: kurz stoppen (SQLite-Konsistenz), sichern, wieder starten
docker compose -f "$STACKS_DIR/vaultwarden/docker-compose.yml" stop
# Sicherheitsnetz: Vaultwarden kommt auch bei Backup-Fehler wieder hoch
trap 'docker compose -f "$STACKS_DIR/vaultwarden/docker-compose.yml" start' EXIT
tar czf "$BACKUP_DIR/vaultwarden-$DATE.tar.gz" -C "$STACKS_DIR/vaultwarden" data
docker compose -f "$STACKS_DIR/vaultwarden/docker-compose.yml" start
trap - EXIT
echo "Vaultwarden gesichert."

# 2) Pi-hole: Teleporter-Export im laufenden Container — kein Stop,
#    der Unbound-Cache bleibt warm
# ponytail: läuft der Timer direkt nach Boot (Persistent=true), kann der
# pihole-Container noch fehlen — dann bricht der Lauf hier ab (Log prüfen)
docker exec -w /etc/pihole pihole pihole-FTL --teleporter
shopt -s nullglob
exports=("$STACKS_DIR"/pihole/etc-pihole/*teleporter*.zip)
if [ ${#exports[@]} -gt 0 ]; then
    mv "${exports[@]}" "$BACKUP_DIR/"
    echo "Pi-hole-Teleporter gesichert."
else
    echo "WARNUNG: kein Teleporter-Export gefunden!" >&2
fi

# 3) Compose-Dateien, .env und Unbound-Config
tar czf "$BACKUP_DIR/configs-$DATE.tar.gz" -C "$STACKS_DIR" \
    --exclude='pihole/etc-pihole' --exclude='vaultwarden/data' \
    pihole vaultwarden

# 4) Rotation
find "$BACKUP_DIR" -type f \( -name '*.tar.gz' -o -name '*.zip' \) \
    -mtime +"$KEEP_DAYS" -delete

echo "[$(date '+%F %T')] Backup fertig:"
# shellcheck disable=SC2012
ls -lh "$BACKUP_DIR" | tail -n 5
