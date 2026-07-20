# VPS-Setup für Christina — Implementierungsplan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Phasen-Skripte, Docker-Stacks und deutsche Doku für ein gehärtetes Debian-13-VPS (Pi-hole+Unbound, Vaultwarden, nur über Tailscale erreichbar), einzurichten an einem Nachmittag entlang eines Runbooks.

**Architecture:** Bash-Phasen-Skripte (`scripts/01…05`) mit gemeinsamer `lib.sh`; zwei Compose-Stacks unter `stacks/`, deren Ports nur an Tailscale-IP/127.0.0.1 binden; Backup per systemd-timer; alles Dokumentierte auf Deutsch. Spec: `docs/superpowers/specs/2026-07-19-vps-christina-design.md`.

**Tech Stack:** Bash (`set -Eeuo pipefail`), shellcheck, Docker Compose v2, pihole/pihole (v6), klutchell/unbound, vaultwarden/server, ufw, fail2ban, tailscale, systemd-timer.

**Hinweise für den Ausführenden:**
- Alle Nutzertexte (log-Ausgaben, Doku) auf **Deutsch**. Code/Variablen englisch.
- Jedes Skript muss `bash -n` und `shellcheck` sauber bestehen.
- Image-Tags beim Implementieren auf die aktuell neueste stabile Version prüfen (Docker Hub) und **pinnen** — die Tags im Plan sind Stand Planungszeitpunkt.
- Commits nach jedem Task, deutsche Commit-Messages.

---

### Task 1: Verzeichnisstruktur + `scripts/lib.sh`

**Files:**
- Create: `scripts/lib.sh`
- Create: `scripts/keys/.gitkeep`

- [x] **Step 1: Verzeichnisse anlegen**

```bash
mkdir -p scripts/keys scripts/systemd stacks/pihole/unbound stacks/vaultwarden handbuch
touch scripts/keys/.gitkeep
```

- [x] **Step 2: `scripts/lib.sh` schreiben**

```bash
#!/bin/bash
# Gemeinsame Funktionen für alle Setup-Skripte.
# Wird per `source` eingebunden, nicht direkt ausführen.

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'

log()     { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
error()   { echo -e "${RED}[FEHLER]${NC} $*" >&2; }

# Greift nur, wenn das aufrufende Skript `set -E` gesetzt hat
trap 'error "Abbruch in Zeile $LINENO (Befehl: $BASH_COMMAND)"' ERR

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "Bitte mit sudo ausführen: sudo bash $0"
        exit 1
    fi
}

require_debian13() {
    # shellcheck disable=SC1091
    . /etc/os-release
    if [ "${ID:-}" != "debian" ] || [ "${VERSION_ID:-}" != "13" ]; then
        error "Dieses Skript ist für Debian 13 gedacht (gefunden: ${PRETTY_NAME:-unbekannt})."
        exit 1
    fi
}
```

- [x] **Step 3: Prüfen**

Run: `bash -n scripts/lib.sh && shellcheck scripts/lib.sh`
Expected: keine Ausgabe (Exit 0)

- [x] **Step 4: Commit**

```bash
git add scripts/ && git commit -m "christina: Grundstruktur + lib.sh (Logging, Root-/Debian-Check)"
```

---

### Task 2: `scripts/01_basis.sh` — Updates, Swap, User, SSH-Härtung, fail2ban

**Files:**
- Create: `scripts/01_basis.sh`

- [x] **Step 1: Skript schreiben**

```bash
#!/bin/bash
# Phase 1: System aktualisieren, Swap, zwei User mit Keys, SSH härten,
# fail2ban und automatische Sicherheitsupdates.
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"

USERS=(christina markus)   # beide bekommen sudo
SWAPFILE=/swapfile
SWAPSIZE=2G

require_root
require_debian13

# Public Keys müssen VOR der SSH-Härtung vorliegen (sonst Aussperr-Gefahr)
for u in "${USERS[@]}"; do
    keyfile="$SCRIPT_DIR/keys/$u.pub"
    if [ ! -s "$keyfile" ] || ! grep -qE '^(ssh-ed25519|ssh-rsa|ecdsa-sha2-|sk-)' "$keyfile"; then
        error "Public Key fehlt oder ist ungültig: scripts/keys/$u.pub — Anleitung: handbuch/mac-basics.md"
        exit 1
    fi
done

log "System aktualisieren ..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y \
    -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

log "Basis-Pakete installieren ..."
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    sudo curl git vim less htop rsync ca-certificates gnupg \
    ufw fail2ban unattended-upgrades

if ! swapon --show=NAME --noheadings | grep -qx "$SWAPFILE"; then
    log "Swapdatei ($SWAPSIZE) anlegen — Sicherheitsnetz bei 1 GB RAM ..."
    fallocate -l "$SWAPSIZE" "$SWAPFILE"
    chmod 600 "$SWAPFILE"
    mkswap "$SWAPFILE"
    swapon "$SWAPFILE"
    grep -q "^$SWAPFILE " /etc/fstab || echo "$SWAPFILE none swap sw 0 0" >> /etc/fstab
    success "Swap aktiv."
else
    log "Swap existiert bereits — übersprungen."
fi

for u in "${USERS[@]}"; do
    if ! id "$u" &>/dev/null; then
        log "Lege User $u an ..."
        adduser --disabled-password --gecos "" "$u"
    fi
    usermod -aG sudo "$u"
    install -d -m 700 -o "$u" -g "$u" "/home/$u/.ssh"
    install -m 600 -o "$u" -g "$u" "$SCRIPT_DIR/keys/$u.pub" "/home/$u/.ssh/authorized_keys"
    if passwd -S "$u" | awk '{print $2}' | grep -qx "L"; then
        log "Passwort für $u setzen (wird für sudo gebraucht):"
        passwd "$u"
    fi
done
success "User angelegt, Keys installiert, sudo aktiv."

log "SSH härten: kein root-Login, kein Passwort-Login ..."
cat > /etc/ssh/sshd_config.d/99-haertung.conf <<'EOF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
EOF
sshd -t
systemctl reload ssh
success "SSH gehärtet. WICHTIG: Login in einem ZWEITEN Terminal testen, bevor du dieses schließt!"

log "fail2ban aktivieren (sperrt IPs nach fehlgeschlagenen SSH-Logins) ..."
cat > /etc/fail2ban/jail.d/sshd.local <<'EOF'
[sshd]
enabled = true
backend = systemd
EOF
systemctl enable --now fail2ban
systemctl restart fail2ban

log "Automatische Sicherheitsupdates aktivieren ..."
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

success "Phase 1 fertig. Weiter im Runbook: Login-Test, dann Phase 2 (Shell)."
```

- [x] **Step 2: Prüfen**

Run: `bash -n scripts/01_basis.sh && shellcheck scripts/01_basis.sh`
Expected: Exit 0, keine Warnungen

- [x] **Step 3: Commit**

```bash
git add scripts/01_basis.sh && git commit -m "christina: 01_basis.sh — Updates, Swap, User, SSH-Härtung, fail2ban"
```

---

### Task 3: `scripts/02_shell.sh` — zsh + oh-my-zsh

**Files:**
- Create: `scripts/02_shell.sh`

- [x] **Step 1: Skript schreiben**

```bash
#!/bin/bash
# Phase 2: zsh + oh-my-zsh für beide User (unbeaufsichtigt, ohne Shell-Wechsel im Skript).
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"

USERS=(christina markus)
require_root

log "zsh installieren ..."
DEBIAN_FRONTEND=noninteractive apt-get install -y zsh

for u in "${USERS[@]}"; do
    home="/home/$u"
    if [ ! -d "$home/.oh-my-zsh" ]; then
        log "oh-my-zsh für $u installieren ..."
        sudo -u "$u" sh -c 'RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
    fi
    for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
        dir="$home/.oh-my-zsh/custom/plugins/$plugin"
        [ -d "$dir" ] || sudo -u "$u" git clone --depth 1 "https://github.com/zsh-users/$plugin" "$dir"
    done
    sudo -u "$u" sed -i 's/^plugins=(git)$/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$home/.zshrc"
    chsh -s "$(command -v zsh)" "$u"
    success "zsh für $u eingerichtet."
done

success "Phase 2 fertig. Beim nächsten Login startet zsh automatisch."
```

- [x] **Step 2: Prüfen**

Run: `bash -n scripts/02_shell.sh && shellcheck scripts/02_shell.sh`
Expected: Exit 0

- [x] **Step 3: Commit**

```bash
git add scripts/02_shell.sh && git commit -m "christina: 02_shell.sh — zsh + oh-my-zsh für beide User"
```

---

### Task 4: `scripts/03_docker.sh` — Docker-Install + Daemon-Härtung

**Files:**
- Create: `scripts/03_docker.sh`

- [x] **Step 1: Skript schreiben**

```bash
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
```

- [x] **Step 2: Prüfen**

Run: `bash -n scripts/03_docker.sh && shellcheck scripts/03_docker.sh`
Expected: Exit 0

- [x] **Step 3: Commit**

```bash
git add scripts/03_docker.sh && git commit -m "christina: 03_docker.sh — Docker-Install + Daemon-Härtung"
```

---

### Task 5: `scripts/04_tailscale.sh` — Tailscale-Install + Anmeldung

**Files:**
- Create: `scripts/04_tailscale.sh`

- [x] **Step 1: Skript schreiben**

Wichtig: `--accept-dns=false`, denn dieses VPS **ist** später der DNS-Server des
Tailnets — es darf nicht selbst vom Pi-hole-Container abhängen (sonst kein DNS
auf dem Host, wenn der Container mal steht).

```bash
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
```

- [x] **Step 2: Prüfen**

Run: `bash -n scripts/04_tailscale.sh && shellcheck scripts/04_tailscale.sh`
Expected: Exit 0

- [x] **Step 3: Commit**

```bash
git add scripts/04_tailscale.sh && git commit -m "christina: 04_tailscale.sh — Install + Anmeldung (accept-dns=false)"
```

---

### Task 6: `scripts/05_lockdown.sh` — Firewall scharf schalten

**Files:**
- Create: `scripts/05_lockdown.sh`

- [x] **Step 1: Skript schreiben**

```bash
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
```

- [x] **Step 2: Prüfen**

Run: `bash -n scripts/05_lockdown.sh && shellcheck scripts/05_lockdown.sh`
Expected: Exit 0

- [x] **Step 3: Commit**

```bash
git add scripts/05_lockdown.sh && git commit -m "christina: 05_lockdown.sh — ufw mit Tailscale-Ausnahme, Aussperr-Schutz"
```

---

### Task 7: Pi-hole+Unbound-Stack

**Files:**
- Create: `stacks/pihole/docker-compose.yml`
- Create: `stacks/pihole/unbound/custom.conf`
- Create: `stacks/pihole/.env.example`

- [x] **Step 1: `stacks/pihole/docker-compose.yml` schreiben**

Image-Tags vor dem Commit auf aktuelle stabile Versionen prüfen und pinnen.
Kein `cap_drop` bei Pi-hole: das Image braucht mehrere Capabilities
(CHOWN, NET_BIND_SERVICE, SETUID, …) und verwaltet sie selbst; `no-new-privileges`
und die Bindung an die Tailscale-IP sind hier die Härtung.

```yaml
services:
  pihole:
    image: pihole/pihole:2025.06.2
    container_name: pihole
    hostname: pihole
    environment:
      TZ: Europe/Berlin
      FTLCONF_webserver_api_password: ${PIHOLE_PASSWORD}
      FTLCONF_dns_upstreams: unbound#53
      FTLCONF_dns_listeningMode: all
    ports:
      # Nur auf der Tailscale-IP erreichbar — nichts davon ist öffentlich
      - "${TAILSCALE_IP}:53:53/tcp"
      - "${TAILSCALE_IP}:53:53/udp"
      - "${TAILSCALE_IP}:8080:80/tcp"
    volumes:
      - ./etc-pihole:/etc/pihole
    depends_on:
      - unbound
    security_opt:
      - no-new-privileges:true
    mem_limit: 384m
    restart: unless-stopped

  unbound:
    image: klutchell/unbound:1.20.0
    container_name: unbound
    # Keine ports: — nur Pi-hole erreicht Unbound über das interne Docker-Netz
    volumes:
      - ./unbound/custom.conf:/etc/unbound/custom.conf.d/custom.conf:ro
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    mem_limit: 128m
    restart: unless-stopped
```

- [x] **Step 2: `stacks/pihole/unbound/custom.conf` schreiben**

```
server:
    # Rekursiver Resolver: fragt die Root-Server direkt, kein Google/Cloudflare
    qname-minimisation: yes
    prefetch: yes
    # Moderater Cache für 1 GB RAM
    msg-cache-size: 32m
    rrset-cache-size: 64m
    # Achtung: hebt alle TTLs auf mind. 5 Min an — Antworten können so lange
    # veraltet sein (Tradeoff: weniger Anfragen, wärmerer Cache)
    cache-min-ttl: 300
```

- [x] **Step 3: `stacks/pihole/.env.example` schreiben**

```
# Kopieren nach .env und ausfüllen — siehe Runbook Phase 6
# Tailscale-IP des Servers, z. B. 100.101.102.103 (ermitteln: tailscale ip -4)
TAILSCALE_IP=
# Passwort für die Pi-hole-Weboberfläche
PIHOLE_PASSWORD=
```

- [x] **Step 4: Compose-Syntax prüfen**

Run: `cd stacks/pihole && cp .env.example .env && sed -i 's/^TAILSCALE_IP=$/TAILSCALE_IP=100.64.0.1/;s/^PIHOLE_PASSWORD=$/PIHOLE_PASSWORD=test/' .env && docker compose config -q; rm .env; cd -`
Expected: Exit 0, keine Fehlermeldung

- [x] **Step 5: `.env` in `.gitignore` aufnehmen und committen**

```bash
echo "stacks/*/.env" >> .gitignore
git add stacks/pihole .gitignore && git commit -m "christina: Pi-hole+Unbound-Stack — Ports nur auf Tailscale-IP"
```

---

### Task 8: Vaultwarden-Stack

**Files:**
- Create: `stacks/vaultwarden/docker-compose.yml`
- Create: `stacks/vaultwarden/.env.example`

- [x] **Step 1: `stacks/vaultwarden/docker-compose.yml` schreiben**

```yaml
services:
  vaultwarden:
    image: vaultwarden/server:1.34.1
    container_name: vaultwarden
    environment:
      TZ: Europe/Berlin
      # z. B. https://vps.tailnet-name.ts.net — muss zur tailscale-serve-URL passen
      DOMAIN: ${VW_DOMAIN}
      # Beim Einrichten true, nach Christinas erstem Account auf false (Runbook Phase 7)
      SIGNUPS_ALLOWED: ${SIGNUPS_ALLOWED:-false}
    ports:
      # Nur localhost — HTTPS macht `tailscale serve` davor
      - "127.0.0.1:8081:80"
    volumes:
      # ./data legt Docker beim ersten Start selbst an (gehört root) — NIE vorher
      # per mkdir anlegen; Restore aus Backup nur als root entpacken (tar --same-owner)
      - ./data:/data
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    mem_limit: 256m
    restart: unless-stopped
```

- [x] **Step 2: `stacks/vaultwarden/.env.example` schreiben**

```
# Kopieren nach .env und ausfüllen — siehe Runbook Phase 7
# Die HTTPS-Adresse aus `tailscale serve status`, z. B. https://vps.tail1234.ts.net
VW_DOMAIN=
# Nur beim allerersten Start auf true, danach wieder false + `docker compose up -d`
SIGNUPS_ALLOWED=false
```

- [x] **Step 3: Compose-Syntax prüfen**

Run: `cd stacks/vaultwarden && cp .env.example .env && sed -i 's|^VW_DOMAIN=$|VW_DOMAIN=https://test.ts.net|' .env && docker compose config -q; rm .env; cd -`
Expected: Exit 0

- [x] **Step 4: Commit**

```bash
git add stacks/vaultwarden && git commit -m "christina: Vaultwarden-Stack — localhost-only, HTTPS via tailscale serve"
```

---

### Task 9: Backup — `scripts/backup.sh` + systemd-Units

**Files:**
- Create: `scripts/backup.sh`
- Create: `scripts/systemd/christina-backup.service`
- Create: `scripts/systemd/christina-backup.timer`

- [x] **Step 1: `scripts/backup.sh` schreiben**

```bash
#!/bin/bash
# Nächtliches Backup — wird von christina-backup.timer um 04:00 aufgerufen.
# Läuft als root. Sichert nach /srv/backups (synct später Syncthing zur NAS).
set -Eeuo pipefail

BACKUP_DIR=/srv/backups
STACKS_DIR=/srv/docker
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
ls -lh "$BACKUP_DIR" | tail -n 5
```

- [x] **Step 2: `scripts/systemd/christina-backup.service` schreiben**

```ini
[Unit]
Description=Nächtliches Backup (Vaultwarden, Pi-hole, Configs)
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh
StandardOutput=append:/var/log/christina-backup.log
StandardError=append:/var/log/christina-backup.log
```

- [x] **Step 3: `scripts/systemd/christina-backup.timer` schreiben**

```ini
[Unit]
Description=Backup täglich um 04:00

[Timer]
OnCalendar=*-*-* 04:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

- [x] **Step 4: Prüfen**

Run: `bash -n scripts/backup.sh && shellcheck scripts/backup.sh && systemd-analyze verify scripts/systemd/christina-backup.service 2>&1 | grep -v "Command.*not found" || true`
Expected: bash/shellcheck Exit 0 (systemd-analyze meckert lokal ggf. über den ExecStart-Pfad — das ist okay, der existiert erst auf dem VPS)

- [x] **Step 5: Commit**

```bash
git add scripts/backup.sh scripts/systemd/ && git commit -m "christina: Backup-Skript + systemd-Timer (04:00, 14 Tage Rotation)"
```

---

### Task 10: `runbook.md` — das Nachmittags-Drehbuch

**Files:**
- Create: `runbook.md`

- [x] **Step 1: Runbook schreiben**

Deutsch, du-Form, Zielgruppe: Markus liest vor/erklärt, Christina tippt.
Jede Phase hat exakt diese vier Blöcke: **Was machen wir? / Warum? /
Befehle / Woran sehen wir, dass es geklappt hat?**

Gliederung und Pflichtinhalte (Befehle exakt so aufnehmen):

- **Phase 0 — Vorbereitung daheim (vor dem Nachmittag):**
  - SSH-Keys am Mac erzeugen → Verweis auf `handbuch/mac-basics.md`; beide `.pub`-Dateien nach `scripts/keys/christina.pub` und `scripts/keys/markus.pub` kopieren
  - Tailscale-Account anlegen (tailscale.com, „Sign up", mit Apple-ID möglich) — noch nichts installieren
  - VPS-Zugangsdaten (IP, root-Passwort vom Hoster) bereitlegen
  - Repo auf den VPS bringen: `ssh root@<VPS-IP>`, dann `apt-get update && apt-get install -y git && git clone <REPO-URL> /opt/setup && cd /opt/setup`
- **Phase 1:** `bash scripts/01_basis.sh` — erklärt Updates, Swap, User, SSH-Härtung. Verifikation: **zweites Terminal**, `ssh christina@<VPS-IP>` mit Key klappt, `ssh root@...` wird abgelehnt. Warnbox: erstes Terminal offen lassen bis der Test klappt.
- **Phase 2:** `bash scripts/02_shell.sh`, neu einloggen, zsh zeigen (Tab-Vervollständigung, Vorschläge beim Tippen)
- **Phase 3:** `bash scripts/03_docker.sh`, neu einloggen, `docker ps` → leere Liste erklären
- **Phase 4:** `bash scripts/04_tailscale.sh` → Login-URL im Mac-Browser öffnen; Tailscale-App auf Mac (App Store) und iPhone installieren und anmelden; Verifikation: Server erscheint in der Tailscale-App, `tailscale status` auf dem VPS
- **Phase 5:** SICHERHEITS-CHECK-Box: zweites Terminal, `ssh christina@<Tailscale-IP>` muss klappen, erst dann `bash scripts/05_lockdown.sh`; Verifikation: `ssh christina@<öffentliche-IP>` läuft ins Leere (Timeout) — und das ist gut so
- **Phase 6 — Pi-hole:**
  - `mkdir -p /srv/docker && cp -r /opt/setup/stacks/* /srv/docker/`
  - `cd /srv/docker/pihole && cp .env.example .env`, `tailscale ip -4` → IP in `.env` eintragen, Passwort setzen, `docker compose up -d`
  - Web-UI: `http://<Tailscale-IP>:8080/admin` am Mac
  - Tailscale-Admin-Konsole (login.tailscale.com) → DNS → Nameserver = `<Tailscale-IP>`, „Override local DNS" aktivieren
  - Test am iPhone (mit aktivem Tailscale): Werbe-lastige Seite öffnen → Werbung weg; im Pi-hole-Dashboard die Queries zeigen
- **Phase 7 — Vaultwarden:**
  - Tailscale-Admin → DNS → MagicDNS + HTTPS Certificates aktivieren
  - `cd /srv/docker/vaultwarden && cp .env.example .env`, `SIGNUPS_ALLOWED=true` setzen, `VW_DOMAIN=https://<maschinenname>.<tailnet>.ts.net` (Name aus `tailscale status`), `docker compose up -d`
  - `tailscale serve --bg http://127.0.0.1:8081` → Zert wird automatisch geholt
  - Am Mac `https://<maschinenname>.<tailnet>.ts.net` öffnen, Christinas Account anlegen (starkes Master-Passwort! Zettel + sicherer Ort)
  - Danach: `.env` → `SIGNUPS_ALLOWED=false`, `docker compose up -d`
  - Bitwarden-App auf Mac/iPhone: „Selbst gehostet", Server-URL eintragen, anmelden
- **Phase 8 — Backup:**
  - `cp /opt/setup/scripts/backup.sh /usr/local/bin/ && chmod +x /usr/local/bin/backup.sh`
  - `cp /opt/setup/scripts/systemd/christina-backup.* /etc/systemd/system/ && systemctl daemon-reload && systemctl enable --now christina-backup.timer`
  - Testlauf: `systemctl start christina-backup.service`, dann `ls -lh /srv/backups` und `cat /var/log/christina-backup.log` gemeinsam anschauen
  - `systemctl list-timers christina-backup.timer` → nächste Ausführung 04:00 zeigen
- **Abschluss-Checkliste:** 10 Punkte zum Abhaken (root-Login zu, Passwort-Login zu, ufw aktiv, öffentl. SSH tot, Pi-hole filtert, Vaultwarden-App am iPhone läuft, Signups aus, Backup gelaufen, beide kennen die Handbuch-Dateien, Tailscale-App auf allen Geräten)

- [x] **Step 2: Commit**

```bash
git add runbook.md && git commit -m "christina: Runbook — Nachmittags-Drehbuch Phase 0-8"
```

---

### Task 11: `handbuch/mac-basics.md`

**Files:**
- Create: `handbuch/mac-basics.md`

- [x] **Step 1: Schreiben**

Zielgruppe Christina, absolute Anfängerin, nur Apple-Geräte. Pflichtinhalte:

- **Terminal öffnen:** Cmd+Leertaste (Spotlight) → „Terminal" tippen → Enter. Kurz erklären was das ist („Textfenster, in dem man dem Computer direkt Befehle gibt")
- **SSH-Key erzeugen:** `ssh-keygen -t ed25519 -C "christina@mac"` — jede Abfrage erklären (Speicherort: Enter = Standard; Passphrase: empfohlen, ist das „Passwort für den Schlüssel"). Erklären: privater Schlüssel bleibt IMMER auf dem Mac, nur die `.pub`-Datei wird weitergegeben
- **Public Key anzeigen/kopieren:** `cat ~/.ssh/id_ed25519.pub` und `pbcopy < ~/.ssh/id_ed25519.pub` („jetzt ist er in der Zwischenablage")
- **`~/.ssh/config` einrichten** (damit `ssh vps` reicht):
  ```
  Host vps
      HostName <Tailscale-IP>
      User christina
  ```
  mit `nano ~/.ssh/config` — nano-Grundlagen: Ctrl+O speichern, Ctrl+X beenden
- **Verbinden:** `ssh vps`, erste-Verbindung-Fingerprint-Frage erklären („einmalig, mit yes bestätigen")
- **Schlüsselbund:** `ssh-add --apple-use-keychain ~/.ssh/id_ed25519` — Passphrase im macOS-Schlüsselbund, nie wieder eintippen

- [x] **Step 2: Commit**

```bash
git add handbuch/mac-basics.md && git commit -m "christina: Handbuch Mac-Basics — Terminal, SSH-Keys, ssh-config"
```

---

### Task 12: `handbuch/linux-basics.md` + `handbuch/docker-basics.md`

**Files:**
- Create: `handbuch/linux-basics.md`
- Create: `handbuch/docker-basics.md`

- [x] **Step 1: `linux-basics.md` schreiben**

Pflichtinhalte, jeweils Befehl + ein Satz was er zeigt + Beispielausgabe:

- Orientierung: `pwd`, `ls`, `ls -lh`, `cd`, `cd ..`, `cat`, `less` (q zum Beenden)
- „Wer bin ich, wo bin ich": `whoami`, `hostname`
- sudo erklären („kurz Chef sein — deshalb fragt er nach DEINEM Passwort")
- Updates selbst machen: `sudo apt update` (Liste holen) vs. `sudo apt upgrade` (installieren) — der Unterschied in einem Satz; Hinweis: Sicherheitsupdates macht der Server nachts automatisch
- Dienste: `systemctl status ssh`, `systemctl status docker` — lesen: grün/active = gut
- Logs: `journalctl -u docker --since today`, `journalctl -f` (Ctrl+C zum Beenden)
- Platz & Speicher: `df -h /`, `free -h`
- Neustart: `sudo reboot` — und dass danach 1–2 Minuten Geduld nötig sind

- [x] **Step 2: `docker-basics.md` schreiben**

Pflichtinhalte:

- Container-Konzept in 3 Sätzen (Analogie: Fertiggericht — alles drin, isoliert vom Rest der Küche)
- `docker ps` — Spalten erklären (NAMES, STATUS „Up 3 days" = gut)
- `docker logs pihole --tail 50`, `docker logs vaultwarden --tail 50`
- „Wo liegen meine Daten?": `/srv/docker/pihole` und `/srv/docker/vaultwarden` — die Container sind wegwerfbar, die Ordner sind das Wertvolle
- Neustart eines Dienstes: `cd /srv/docker/pihole && docker compose restart`
- **Updates:** `cd /srv/docker/vaultwarden && docker compose pull && docker compose up -d` — Hinweis: Image-Versionen sind gepinnt, Update = Version in `docker-compose.yml` erhöhen (macht am Anfang Markus)
- Aufräumen: `docker image prune -f` (alte Versionen löschen, spart Platz)

- [x] **Step 3: Commit**

```bash
git add handbuch/linux-basics.md handbuch/docker-basics.md && git commit -m "christina: Handbuch Linux- und Docker-Basics"
```

---

### Task 13: `handbuch/tailscale.md` + `handbuch/notfall.md`

**Files:**
- Create: `handbuch/tailscale.md`
- Create: `handbuch/notfall.md`

- [x] **Step 1: `tailscale.md` schreiben**

Pflichtinhalte:

- Was ist ein Tailnet, in 3 Sätzen (Analogie: privater Tunnel zwischen DEINEN Geräten, unsichtbar für den Rest des Internets)
- Warum: der Server hat eine öffentliche Adresse, aber alles Wichtige ist nur durch den Tunnel erreichbar
- Mac-App: Menüleisten-Icon, verbunden/getrennt erkennen, Geräteliste
- iPhone-App: VPN-Symbol, was es bedeutet, App muss an sein damit DNS-Filter + Vaultwarden funktionieren — „kein Internetproblem, sondern: ist Tailscale an?"
- Admin-Konsole login.tailscale.com: Geräteliste, neues Gerät hinzufügen (App installieren + anmelden, fertig), Gerät entfernen
- Wo der DNS-Eintrag steht (DNS → Nameserver) und was er tut (alle DNS-Fragen gehen zum Pi-hole)
- Key-Expiry: Hinweis, dass Markus für den Server „Disable key expiry" gesetzt hat (in Admin-Konsole → Maschine → … → Disable key expiry) — auch als Runbook-Phase-4-Punkt erwähnen

- [x] **Step 2: `notfall.md` schreiben**

Als Entscheidungsbaum/Checkliste, von häufig nach selten:

1. „Internet geht nicht / Seiten laden nicht" → Ist Tailscale am Gerät an? (häufigster Fall!) → App öffnen, verbinden
2. „Werbung ist plötzlich wieder da" → wie 1., sonst: Pi-hole-Dashboard erreichbar? `http://<Tailscale-IP>:8080/admin`
3. „Bitwarden synct nicht" → wie 1., sonst Mac: `ssh vps`, dann `docker ps` — läuft vaultwarden?
4. Container steht: `cd /srv/docker/<dienst> && docker compose restart`, Logs: `docker logs <dienst> --tail 50`
5. Server komplett weg: Hoster-Webkonsole (Notfall-Zugang, funktioniert ohne SSH), `sudo reboot`
6. „Backup ok?": `systemctl list-timers christina-backup.timer`, `ls -lh /srv/backups`, `tail /var/log/christina-backup.log`
7. Goldene Regeln: Nichts löschen was man nicht kennt. Bei Unsicherheit: Markus anrufen — Schritt-Nummer aus dieser Liste durchgeben.

- [x] **Step 3: Commit**

```bash
git add handbuch/tailscale.md handbuch/notfall.md && git commit -m "christina: Handbuch Tailscale + Notfall-Checkliste"
```

---

### Task 14: Gesamt-Verifikation

**Files:** keine neuen

- [x] **Step 1: Alle Skripte prüfen**

Run: `find scripts -name '*.sh' -exec bash -n {} \; && find scripts -name '*.sh' -exec shellcheck {} \;`
Expected: Exit 0, keine Findings

- [x] **Step 2: Compose-Dateien validieren**

Beide Stacks wie in Task 7/8 Step 4 mit Dummy-`.env` per `docker compose config -q` prüfen.
Expected: Exit 0

- [x] **Step 3: Doku-Querverweise prüfen**

Prüfen, dass jede in `runbook.md` referenzierte Datei existiert (`handbuch/*.md`, `scripts/*.sh`, Pfade `/srv/docker`, `/opt/setup` konsistent verwendet).

- [x] **Step 4: Plan-Checkboxen aktualisieren + finaler Commit**

```bash
git add -A && git commit -m "christina: Gesamt-Verifikation — shellcheck, compose config, Querverweise"
```

**Manueller Test vor dem Nachmittag (nicht Teil dieses Plans, aber Pflicht):**
Kompletter Probelauf auf einem Wegwerf-Debian-13-System (Test-VPS oder VM) —
insbesondere Phase 1 (Aussperr-Risiko), Pi-hole-Start mit `cap`-/Port-Setup
und ein voller Backup-Lauf. Syntax-Checks ersetzen keinen echten Durchlauf.
