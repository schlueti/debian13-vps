# Probelauf-Checkliste (vor dem Nachmittag mit Christina)

Pflicht: kompletter Durchlauf auf einem Wegwerf-Debian-13 (Test-VPS oder VM).
Diese Punkte stammen aus den Code-Reviews und lassen sich nur am echten System
prüfen.

## Phase 1–5 (Skripte)

- [ ] Kompletter Durchlauf von `01_basis.sh` bis `05_lockdown.sh` — besonders
      Phase 1 (Aussperr-Risiko: SSH-Härtung erst testen, dann Fenster schließen)
- [ ] `02_shell.sh`: bei curl-/GitHub-Fehler kommen verwirrende Folgefehler
      (git clone) — Ausgabe im Blick behalten

## Pi-hole / Unbound

- [ ] `docker compose config` mit echter `.env`: rendert die Tailscale-IP
      korrekt in den `ports:` (leere Variable = Footgun)
- [ ] Erste Boot-Logs von Pi-hole unter daemon-weitem `no-new-privileges`
      anschauen (`docker logs pihole`)
- [ ] Unbound lauscht auf :53 — via `docker compose logs unbound` prüfen
      (distroless, kein `docker exec … sh` möglich) und Test-Query aus dem
      Pi-hole-Container
- [ ] Unbound-RAM vs. `mem_limit: 128m` unter Last beobachten
      (`docker stats`, OOM-Kills via `dmesg`)
- [ ] Nach `docker compose up --force-recreate unbound`: löst Pi-hole den
      Upstream noch auf? (sonst pihole mit neustarten)
- [ ] Start-Race: `depends_on` garantiert keine Unbound-Bereitschaft — nur
      transiente Timeouts in den ersten Sekunden sind okay, kein Dauerfehler

## Vaultwarden

- [ ] `VW_DOMAIN` VOR dem ersten Login korrekt setzen (klassischer Footgun
      für WebAuthn/Icons)
- [ ] Passkey-/WebAuthn-Registrierung mit echtem iPhone über die reale
      tailscale-serve-URL testen
- [ ] Icon-Fetch funktioniert (Container braucht Outbound-Egress)

## Backup

- [ ] Einen vollen Backup-Lauf ausführen (`systemctl start christina-backup.service`)
- [ ] Backup-Fehlerfall simulieren (z. B. `/srv/backups` kurz unbeschreibbar
      machen): Vaultwarden muss trotzdem wieder hochkommen (EXIT-Trap)
- [ ] Einen Restore-Zyklus testen: als root entpacken (`tar --same-owner`),
      danach Ownership von `./data` prüfen (muss root gehören)

## Gesamt

- [ ] RAM-Gesamtfootprint aller Stacks + Tailscale unter Last auf dem 1GB-Host
      (`free -h`, Swap-Nutzung)
