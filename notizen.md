# Admin-Notizen — debian13-vps

Kurze Ops-Referenz für Markus. Der VPS wird allein über Tailscale administriert.
(Frühere Schritt-für-Schritt-Einrichtung: in der git-Historie, `runbook.md` vor
2026-07-23.)

## Architektur

- **Host**: Debian 13, nur über Tailscale erreichbar (ufw dicht, kein öffentlicher Port).
- **Docker-Stacks** unter `/opt/setup/stacks/` — das git-Repo IST das Deploy-Verzeichnis
  (Single Source of Truth, `markus` gehört der Checkout, kein sudo für Deploy).
- **Pi-hole + Unbound**: DNS fürs Tailnet. Unbound resolved rekursiv gegen die
  Root-Server (kein Upstream), DNSSEC-validiert. Pi-hole nur auf der Tailscale-IP.
- **Vaultwarden**: Passwort-Manager, nur auf `127.0.0.1`, per `tailscale serve` mit
  HTTPS ins Tailnet gereicht.
- **Backup**: nächtlicher systemd-Timer → `/srv/backups`.

## Deploy-Zyklus (jeder Stack)

```bash
cd /opt/setup && git pull                       # kein sudo (Checkout gehört markus)
cd stacks/<pihole|vaultwarden>
docker compose up -d                            # Änderung anwenden
docker compose logs -f                          # prüfen
```

`.env` je Stack liegt lokal im Ordner (aus `.env.example` kopiert, git-ignoriert).

## Pi-hole

- Web-UI: `http://<TAILSCALE_IP>:8080/admin`, Passwort in `stacks/pihole/.env`.
- Als DNS im Tailnet aktiv: Tailscale-Admin → **DNS** → Nameserver = `<TAILSCALE_IP>`,
  „Override local DNS" an.
- Blocklisten: `stacks/pihole/blocklists.md`. Nach Listen-Änderung `docker exec pihole pihole -g`.
- Funktionstest: `docker exec pihole dig @unbound google.com +short`.
- **Unbound-Eigenheit** (nicht anfassen): läuft als `user: "101:102"` + `username: ""`
  in der Config, weil `cap_drop: ALL` den normalen Privilege-Drop verhindert.
- **Host-DNS**: `systemd-resolved` Stub-Listener auf :53 ist aus
  (`scripts/06_pihole_dns.sh`), sonst kollidiert er mit Pi-hole. Host nutzt festen
  Upstream (nicht Pi-hole → kein Boot-Henne-Ei).

## Vaultwarden

- URL: `https://<maschine>.<tailnet>.ts.net` (aus `tailscale status`), muss `VW_DOMAIN` in
  `stacks/vaultwarden/.env` entsprechen.
- HTTPS-Reverse-Proxy: `tailscale serve --bg http://127.0.0.1:8081` (einmalig).
- Registrierung: `SIGNUPS_ALLOWED=true` nur zum Anlegen eines Accounts, danach
  `false` + `docker compose up -d`.
- `./data` NIE von Hand anlegen (legt Docker als root an).

## Backup

- Timer: `christina-backup.timer`, nachts 04:00 → `/srv/backups` (14 Tage Rotation).
- Sichert: Vaultwarden-`data` (Container kurz gestoppt), Pi-hole-Teleporter-Export,
  Compose/.env/Unbound-Config. Script: `scripts/backup.sh` (`STACKS_DIR=/opt/setup/stacks`).
- Bei Script-Änderung neu ausrollen:
  ```bash
  sudo cp /opt/setup/scripts/backup.sh /usr/local/bin/ && sudo chmod +x /usr/local/bin/backup.sh
  ```
- Manueller Lauf/Check: `sudo systemctl start christina-backup.service && cat /var/log/christina-backup.log`

## Tailscale

- Server-Key-Expiry in der Admin-Konsole deaktiviert (sonst fällt der VPS irgendwann raus).
- `tailscale ip -4` → die `100.x`-Adresse (= `TAILSCALE_IP` in der Pi-hole-.env).

### Zweite tailscaled-Instanz auf meinem Rechner (Headscale ↔ Christinas Tailnet)

Läuft auf **meinem lokalen Rechner**, nicht auf dem VPS. Eigener State/Socket/TUN,
damit die Headscale-Instanz unberührt bleibt (beide können parallel laufen).
Auth-Key stellt Christina aus (siehe `fuer-christina.md` Teil 5).

```ini
# /etc/systemd/system/tailscaled-freundin.service
[Unit]
Description=Tailscale (Freundin) — zweite Instanz
After=network-pre.target
Wants=network-pre.target

[Service]
ExecStart=/usr/sbin/tailscaled \
  --state=/var/lib/tailscale-freundin/tailscaled.state \
  --socket=/run/tailscale-freundin/tailscaled.sock \
  --tun=tailscale-fr \
  --port=0
RuntimeDirectory=tailscale-freundin
StateDirectory=tailscale-freundin
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload && sudo systemctl enable --now tailscaled-freundin
sudo tailscale --socket=/run/tailscale-freundin/tailscaled.sock up --authkey tskey-auth-...
# Steuerung immer über den Socket (Alias empfohlen):
alias ts-fr='tailscale --socket=/run/tailscale-freundin/tailscaled.sock'
ts-fr status   # ts-fr up / ts-fr down zum Wechseln
```
