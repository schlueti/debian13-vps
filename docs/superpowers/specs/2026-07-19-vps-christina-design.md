# Design: VPS-Setup für Christina (Debian 13, 1 CPU / 1 GB)

Datum: 2026-07-19
Status: vom Auftraggeber genehmigt (Gesprächsverlauf 2026-07-19)

## Ziel

Ein Debian-13-VPS als „souveräner" Selfhosting-Einstieg für Christina
(Linux-Neuling): Pi-hole + Unbound und Vaultwarden in Docker, ausschließlich
über Tailscale erreichbar, gehärtet, mit nächtlichen lokalen Backups.
Markus fungiert als Admin; Christina soll Schritt für Schritt selbständig
werden. Die Einrichtung passiert an einem gemeinsamen Nachmittag entlang
eines Runbooks — die Skripte machen bewusst **nicht** alles automatisch.

## Entscheidungen (mit Begründung)

| Thema | Entscheidung | Warum |
|---|---|---|
| Vaultwarden-HTTPS | `tailscale serve` mit ts.net-Zertifikat | Kein Reverse-Proxy, kein offener Port, kein Cert-Management. Die All-inkl-Domain wird NICHT benutzt. |
| Skript-Format | Phasen-Skripte + deutsches Runbook | Christina tippt und versteht mit; manuelle Schritte bleiben bewusst manuell. |
| User | `christina` + Admin-User, beide sudo | Lernziel Selbständigkeit; root-Login wird deaktiviert. |
| Firewall | ufw (deny incoming, allow `tailscale0`) + Container-Ports nur an Tailscale-IP/127.0.0.1 binden | Docker umgeht ufw via iptables; durch das Binden lauscht auf dem öffentlichen Interface schlicht nichts. ufw ist zweite Verteidigungslinie für SSH. |
| Backups | tar + systemd-timer nach `/srv/backups`, 14 Tage Rotation | Nachvollziehbar („das sind Dateien"), Syncthing synct das Verzeichnis später zur NAS. Syncthing wird jetzt noch nicht installiert. |
| Pi-hole/Unbound-Backup | Teleporter-Export ohne Container-Stop | Unbound-Cache lebt nur im RAM; kein nächtlicher Neustart → Cache bleibt warm. |
| Sprache | Alles Deutsch (Doku + Skript-Ausgaben) | Zielgruppe. Code/Variablennamen englisch. |
| Client-Geräte | Christina nutzt ausschließlich Apple-Geräte (Mac, iPhone) | Alle Client-Anleitungen (Terminal.app, SSH-Keys, Tailscale-/Bitwarden-Apps) sind auf macOS/iOS ausgelegt. |

## Architektur

```
Internet ──► VPS (öffentl. IP)          nichts erreichbar außer Tailscale (UDP, outbound)
                │
                ├─ ufw: deny incoming, allow tailscale0
                ├─ sshd: nur Pubkey, kein root, kein Passwort — nur via Tailscale
                ├─ fail2ban (Schutz während Einrichtungsphase)
                ├─ Tailscale ──► Christinas Geräte (Handy, Laptop)
                │
                ├─ Docker
                │   ├─ Stack pihole/:  Pi-hole + Unbound   → lauscht auf 100.x:53 + Web-UI
                │   └─ Stack vaultwarden/:  Vaultwarden    → lauscht auf 127.0.0.1
                │        └─ tailscale serve → https://<vps>.<tailnet>.ts.net
                │
                └─ Backup: systemd-timer 04:00 → /srv/backups/*.tar.gz (14 Tage)
```

- **DNS-Kette:** Geräte → Tailscale-DNS → Pi-hole (Filter) → Unbound
  (rekursiv, DNSSEC, kein Google/Cloudflare-Upstream).
- **RAM:** Pi-hole+Unbound+Vaultwarden ≈ 400–500 MB. Zusätzlich 2-GB-Swapdatei
  als Sicherheitsnetz; Docker-Log-Limits gegen vollaufende Platte.
- **Updates:** `unattended-upgrades` für Sicherheitspatches; reguläre Updates
  macht Christina nach Handbuch (`apt update && apt upgrade`,
  `docker compose pull && up -d`).

## Repo-Struktur

```
christina/
├── runbook.md              ← Nachmittags-Drehbuch: pro Phase WAS/WARUM,
│                              Skript-Aufruf, manuelle Schritte, Verifikation
├── handbuch/
│   ├── mac-basics.md       ← Terminal.app öffnen, ssh-Keys erzeugen (ssh-keygen),
│   │                          ~/.ssh/config, Key-Handling auf dem Mac
│   ├── linux-basics.md     ← ssh, cd/ls, systemctl, journalctl
│   ├── docker-basics.md    ← ps, logs, compose pull/up, „wo liegen meine Daten"
│   ├── tailscale.md        ← Tailnet-Konzept, App-Bedienung, Gerät hinzufügen
│   └── notfall.md          ← „Es geht nichts mehr"-Checkliste
├── scripts/
│   ├── 01_basis.sh         ← Updates, Swap, 2 User+Keys, sshd härten,
│   │                          fail2ban, unattended-upgrades
│   ├── 02_shell.sh         ← zsh + oh-my-zsh für beide User
│   ├── 03_docker.sh        ← Docker-Install + daemon.json-Härtung
│   │                          (log-limits, no-new-privileges, live-restore)
│   ├── 04_tailscale.sh     ← Install + `tailscale up` (Login manuell im Browser)
│   ├── 05_lockdown.sh      ← ufw scharf — erst nach verifiziertem SSH-über-Tailscale
│   └── backup.sh           ← nächtliches Backup (vom Timer aufgerufen)
└── stacks/
    ├── pihole/docker-compose.yml   + unbound/-Config
    └── vaultwarden/docker-compose.yml
```

**Bewusst manuell im Runbook:** Tailscale-Browser-Login, Pi-hole als DNS im
Tailscale-Admin eintragen, `tailscale serve` einrichten, finaler
„SSH öffentlich zu"-Moment, erster Vaultwarden-Account + danach
`SIGNUPS_ALLOWED=false`.

**Container-Härtung (Compose):** `no-new-privileges`, `cap_drop: ALL`
(+ nur nötige Caps zurück), Memory-Limits, `restart: unless-stopped`,
gepinnte Image-Tags statt `latest`.

## Backup-Ablauf

Nächtlich 04:00 via `backup.timer` → `backup.service` → `backup.sh`:

1. **Vaultwarden:** Container stoppen → Datenverzeichnis als
   `/srv/backups/vaultwarden-JJJJ-MM-TT.tar.gz` → Container starten
   (Downtime ~10 s).
2. **Pi-hole:** Teleporter-Export im laufenden Container → Zip ins
   Backup-Verzeichnis. Kein Stop.
3. **Compose-Dateien + Unbound-Config:** mitkopieren.
4. **Rotation:** älter als 14 Tage löschen.
5. Ergebnis in Logdatei; Handbuch erklärt die Kontrolle
   (`systemctl status backup.timer`, `ls -lh /srv/backups`).

## Ablaufplan Nachmittag (= Runbook-Gliederung)

| Phase | Was | Wer tippt |
|---|---|---|
| 0 | Vorbereitung daheim: SSH-Keys am Mac erzeugen (nach `mac-basics.md`), Tailscale-Account, VPS-Zugangsdaten | vorher |
| 1 | `01_basis.sh`: Updates, Swap, User, SSH-Härtung, fail2ban | Christina |
| 2 | `02_shell.sh`: zsh/oh-my-zsh | Christina |
| 3 | `03_docker.sh` + erster `docker ps` | Christina |
| 4 | `04_tailscale.sh` + Browser-Login, App aufs Handy | beide |
| 5 | Verifikation SSH-über-Tailscale, dann `05_lockdown.sh` | Markus |
| 6 | Pi-hole-Stack starten, DNS im Tailscale-Admin, am Handy testen | beide |
| 7 | Vaultwarden-Stack + `tailscale serve`, Account anlegen, Signups aus | Christina |
| 8 | Backup-Timer aktivieren, Testlauf, Ergebnis anschauen | Christina |

Jede Phase: **Was machen wir? Warum? Befehl. Woran sehen wir, dass es
geklappt hat?** Phase 5 hat eine explizite „nicht weitermachen
bevor..."-Sperre gegen Aussperren.

## Fehlerbehandlung & Tests

- Alle Skripte: `set -euo pipefail`, Error-Trap mit Zeilennummer, deutsche
  `log()`/`success()`/`error()`-Ausgaben (Repo-Standard).
- Skripte idempotent — zweiter Lauf ist harmlos.
- `01_basis.sh` prüft Debian 13 + root/sudo, sonst Abbruch mit klarer Meldung.
- `05_lockdown.sh` verweigert ohne aktives Tailscale-Interface.
- Test vor dem Nachmittag: Durchlauf in Debian-13-Container,
  `bash -n` + shellcheck für alle Skripte.

## Nicht-Ziele

- Keine öffentliche Erreichbarkeit irgendeines Dienstes.
- Keine Nutzung der All-inkl-Domain (weder Web noch Cert).
- Kein Syncthing, kein Borg/Restic (später, wenn NAS da ist).
- Kein Monitoring-Stack — `notfall.md` + journalctl reichen für den Anfang.
