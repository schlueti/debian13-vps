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
    sudo curl git vim less htop rsync ca-certificates gnupg locales \
    ufw fail2ban unattended-upgrades

log "UTF-8-Locale (de_DE.UTF-8) erzeugen — sonst verrutscht der zsh-Prompt ..."
sed -i 's/^# *de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
update-locale LANG=de_DE.UTF-8
success "Locale gesetzt (greift bei der nächsten Login-Session)."

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
