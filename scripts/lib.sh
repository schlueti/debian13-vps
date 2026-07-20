#!/bin/bash
# Gemeinsame Funktionen für alle Setup-Skripte.
# Wird per `source` eingebunden, nicht direkt ausführen.

# sbin in den PATH, sonst fehlen bei `su` (ohne -) locale-gen, swapon, adduser etc.
export PATH="/usr/local/sbin:/usr/sbin:/sbin:$PATH"

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
