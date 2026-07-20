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
