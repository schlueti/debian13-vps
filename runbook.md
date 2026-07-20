# Runbook: Christinas VPS — das Nachmittags-Drehbuch

Dieses Dokument führt einmal komplett durch die Einrichtung, Phase für Phase.
Christina tippt — auch die root-Befehle in Phase 1–5. Markus liest die
Erklärungen vor, erklärt, und schaut vor jedem Enter mit drauf (bei den zwei
heiklen Momenten in Phase 1 und 5 besonders genau). Verstehen durch Selbermachen
ist der Sinn der Übung.

Jede Phase hat vier Blöcke: **Was machen wir?**, **Warum?**, **Befehle**,
**Woran sehen wir, dass es geklappt hat?**. Wenn eine Verifikation nicht
passt: anhalten, nicht weitermachen, lieber einmal mehr nachfragen.

Alle Befehle ab Phase 1 laufen auf dem VPS, im Verzeichnis `/opt/setup`
(dorthin klont Phase 0 das Repo — `scripts/` und `stacks/` liegen direkt
darunter). Ausnahme ist Phase 0 — die läuft teils am Mac, teils per SSH auf
dem VPS.

---

## Phase 0 — Vorbereitung daheim (vor dem Nachmittag)

**Was machen wir?**
Wir erledigen alles, was Wartezeit hat oder man nicht zu zweit vor dem
Bildschirm braucht: SSH-Keys erzeugen, Tailscale-Account anlegen,
VPS-Zugangsdaten bereitlegen, das Repo auf den Server holen.

**Warum?**
Das spart am Nachmittag selbst Zeit — und ohne den SSH-Key kann Phase 1
gar nicht laufen (das Skript bricht sonst bewusst ab, damit sich niemand
aussperrt).

**Befehle**

- SSH-Key erzeugen: siehe `handbuch/mac-basics.md`. Christina und Markus
  erzeugen je einen eigenen Key auf ihrem Mac und kopieren die jeweilige
  `.pub`-Datei ins Repo nach `scripts/keys/christina.pub` bzw.
  `scripts/keys/markus.pub` (git add/commit/push, damit sie beim Clone auf
  dem Server ankommen).
- Tailscale-Account anlegen: auf [tailscale.com](https://tailscale.com)
  „Sign up" klicken — Login mit Apple-ID geht. Noch **nichts** installieren.
- VPS-Zugangsdaten bereitlegen: IP-Adresse und root-Passwort vom Hoster
  (meist per Mail oder im Kundenportal).
- Repo auf den VPS bringen:
  ```bash
  ssh root@<VPS-IP>
  apt-get update && apt-get install -y git
  git clone <REPO-URL> /opt/setup
  cd /opt/setup
  ```

**Woran sehen wir, dass es geklappt hat?**
`scripts/keys/christina.pub` und `scripts/keys/markus.pub` existieren und
beginnen mit `ssh-ed25519`. Der Tailscale-Account-Login funktioniert im
Browser. Auf dem VPS zeigt `ls /opt/setup` die Ordner `scripts/`
und `stacks/`.

---

## Phase 1 — Basis: Updates, Swap, User, SSH-Härtung

> **Zum Session-Modell:** Phasen 1–5 laufen alle in eurem root-SSH-Fenster
> (das bleibt bis nach Phase 5 offen). Ein zweites Terminal kommt nur für
> die Login-Tests als `christina` dazu. Ab Phase 6 arbeitet Christina in
> ihrer eigenen Session.

**Was machen wir?**
`scripts/01_basis.sh` ausführen: System aktualisieren, 2 GB Swap anlegen,
beide User (Christina, Markus) mit sudo und ihrem SSH-Key einrichten, SSH
härten, fail2ban und automatische Sicherheitsupdates aktivieren.

**Warum?**
Das ist das Fundament, auf dem alles andere aufbaut. Der Swap ist ein
Sicherheitsnetz, weil der Server nur 1 GB RAM hat; fail2ban sperrt IPs
aus, die wiederholt falsche SSH-Logins versuchen; automatische
Sicherheitsupdates schließen Lücken auch nachts, ohne dass jemand daran
denken muss. Und ab jetzt gilt: kein root-Login mehr per SSH, kein
Passwort-Login mehr — nur noch der eigene Schlüssel zählt.

**Befehle**

```bash
bash scripts/01_basis.sh
```

> Das Skript fragt für jeden User einmal ein Passwort ab (wird nur für
> `sudo` gebraucht, nicht für den SSH-Login selbst). Wählt gute Passwörter
> und schreibt sie euch sicher auf, z. B. im Passwortmanager.

**Woran sehen wir, dass es geklappt hat?**

Zweites Terminal am Mac öffnen (das root-Fenster bleibt dabei offen —
es wird noch bis nach Phase 5 gebraucht):

```bash
ssh christina@<VPS-IP>
```

Das muss ohne Passwortabfrage funktionieren (nur der Schlüssel zählt).
Danach testen:

```bash
ssh root@<VPS-IP>
```

Das muss abgelehnt werden („Permission denied").

---

## Phase 2 — Shell: zsh + oh-my-zsh

**Was machen wir?**
`scripts/02_shell.sh` ausführen: zsh mit oh-my-zsh, Autosuggestions,
Syntax-Highlighting und dem powerlevel10k-Theme für beide User einrichten.

**Warum?**
Ein angenehmeres Terminal macht den Rest des Nachmittags leichter —
Tab-Vervollständigung, Farben, Tippvorschläge. Nicht zwingend nötig, aber
spart ab jetzt viel Tipparbeit.

**Befehle**

```bash
bash scripts/02_shell.sh
```

Danach neu einloggen (`exit`, dann wieder `ssh christina@<VPS-IP>`).

**Woran sehen wir, dass es geklappt hat?**
Nach dem Login startet automatisch zsh — der Prompt sieht anders aus.
Beim Tippen erscheinen graue Vorschläge, `Tab` zeigt eine Auswahlliste an.

Beim ersten zsh-Start startet powerlevel10k einen Einrichtungs-Assistenten
(`p10k configure`) — einfach durchklicken. Für die vollen Symbole muss im
Terminal die Schrift **MesloLGS NF** installiert und ausgewählt sein; sonst
`p10k configure` erneut aufrufen und die ASCII-Variante wählen.

Guter Moment für ein paar Minuten Terminal-Spielen: die wichtigsten
Alltagsbefehle (`ls`, `cd`, `cat`, `systemctl status` …) stehen zum
Nachschlagen in `handbuch/linux-basics.md`.

---

## Phase 3 — Docker installieren

**Was machen wir?**
`scripts/03_docker.sh` ausführen: Docker aus dem offiziellen Repository
installieren, den Docker-Daemon härten (Log-Limits, `no-new-privileges`,
`live-restore`).

**Warum?**
Docker ist die „Verpackung" für Pi-hole und Vaultwarden — beide laufen
später als Container. Einmal ordentlich einrichten, dann läuft es.

**Befehle**

```bash
bash scripts/03_docker.sh
```

Danach neu einloggen (die docker-Gruppe greift erst beim nächsten Login),
dann testen:

```bash
docker ps
```

**Woran sehen wir, dass es geklappt hat?**
`docker ps` zeigt eine Tabelle mit Kopfzeile (`CONTAINER ID`, `IMAGE`, …)
und keine Fehlermeldung — noch keine laufenden Container, aber Docker
funktioniert und ihr dürft es ohne `sudo` benutzen.

---

## Phase 4 — Tailscale: der private Tunnel

**Was machen wir?**
`scripts/04_tailscale.sh` ausführen und den Server anmelden. Danach die
Tailscale-App auf Mac und iPhone installieren und mit demselben Account
anmelden. Siehe auch `handbuch/tailscale.md`.

**Warum?**
Tailscale baut dein **Tailnet** auf — dein privates Netz aus deinen
eigenen Geräten, wie ein unsichtbarer Tunnel zwischen ihnen. Alles, was
ab Phase 5 wichtig wird (SSH, Pi-hole, Vaultwarden), läuft nur noch durch
diesen Tunnel — unsichtbar für den Rest des Internets.

**Befehle**

```bash
bash scripts/04_tailscale.sh
```

Es erscheint eine Login-URL — die im Mac-Browser öffnen und mit dem
Tailscale-Account anmelden. Danach:

- Tailscale-App aus dem Mac App Store installieren, anmelden.
- Tailscale-App aus dem iPhone App Store installieren, anmelden.
- In der Tailscale-Admin-Konsole ([login.tailscale.com](https://login.tailscale.com))
  bei der VPS-Maschine auf „…" klicken → **„Disable key expiry"** aktivieren.
  Sonst fällt der Server nach einigen Monaten automatisch aus dem Tailnet,
  weil sein Schlüssel abläuft.
- Auf dem VPS:
  ```bash
  sudo tailscale set --operator=christina
  ```
  Damit darf Christina spätere `tailscale`-Befehle (z. B. `tailscale
  serve` in Phase 7) selbst ausführen, ohne `sudo`.

**Woran sehen wir, dass es geklappt hat?**
Der Server erscheint in der Geräteliste der Tailscale-App. Auf dem VPS
taucht der Server in `tailscale status` in der Liste auf; Mac und iPhone
erscheinen dort mit ihren Gerätenamen. `tailscale ip -4` liefert eine
Adresse wie `100.x.x.x`.

---

## Phase 5 — Lockdown: Firewall scharf schalten

**Was machen wir?**
Erst einen Sicherheits-Test, dann `scripts/05_lockdown.sh` ausführen:
`ufw` aktivieren, sodass der Server von außen komplett dicht ist und nur
noch über Tailscale erreichbar bleibt.

**Warum?**
Ab hier hat der Server keine offene Angriffsfläche mehr im normalen
Internet — SSH und alle Dienste laufen nur noch durch den Tailscale-Tunnel.

> **NICHT WEITERMACHEN, bevor der SSH-Test über die Tailscale-IP
> funktioniert.** Erstes Terminal dabei offen lassen.

**Befehle**

Zweites Terminal am Mac, Test über die Tailscale-IP (aus `tailscale
status` oder `tailscale ip -4`):

```bash
ssh christina@<Tailscale-IP>
```

Erst wenn das klappt, im ersten Terminal:

```bash
bash scripts/05_lockdown.sh
```

Das Skript fragt: „Funktioniert der SSH-Login über die Tailscale-IP?
(ja/nein)" — nur mit `ja` antworten, wenn der Test oben tatsächlich
gelaufen ist.

**Woran sehen wir, dass es geklappt hat?**
`ssh christina@<öffentliche-IP>` (die alte Adresse) läuft jetzt ins Leere
bzw. in einen Timeout — das ist gewollt. Über die Tailscale-IP
funktioniert SSH weiterhin.

---

## Phase 6 — Pi-hole: Werbefilter für das ganze Tailnet

**Was machen wir?**
Die Docker-Stacks nach `/srv/docker` kopieren, Pi-hole + Unbound starten
und als DNS-Server des Tailnets eintragen.

**Warum?**
Pi-hole filtert Werbung und Tracker zentral für alle Geräte im Tailnet —
einmal einrichten, wirkt danach auf Mac und iPhone gleichermaßen. Zwei
Container arbeiten zusammen: Pi-hole filtert die Anfragen, Unbound fragt
danach selbst die Root-Server der DNS-Hierarchie ab — ohne Umweg über
Google oder Cloudflare.

**Befehle**

```bash
sudo mkdir -p /srv/docker && sudo cp -r /opt/setup/stacks/* /srv/docker/
sudo chown -R christina:christina /srv/docker
```

(`/srv` gehört root — der `chown` sorgt dafür, dass Christina `.env`
selbst bearbeiten und `docker compose` ohne `sudo` ausführen kann. Die
Daten-Unterordner, z. B. `./data` von Vaultwarden, legt Docker später
selbst als root an — die NICHT von Hand anfassen.)

```bash
cd /srv/docker/pihole && cp .env.example .env
tailscale ip -4
```

Die ausgegebene IP in `.env` bei `TAILSCALE_IP=` eintragen, dazu ein
Passwort bei `PIHOLE_PASSWORD=` setzen (`nano .env`, Ctrl+O speichern,
Ctrl+X beenden). Dann:

```bash
docker compose up -d
```

Web-UI am Mac aufrufen: `http://<Tailscale-IP>:8080/admin`

Danach in der Tailscale-Admin-Konsole: **DNS** → Nameserver hinzufügen =
`<Tailscale-IP>`, **„Override local DNS"** aktivieren.

**Woran sehen wir, dass es geklappt hat?**
Am iPhone (mit aktivem Tailscale) eine werbelastige Seite öffnen — die
Werbung fehlt. Im Pi-hole-Dashboard unter „Query Log" tauchen Anfragen
von Mac und iPhone auf. Grundbefehle für den Alltag mit Docker:
`handbuch/docker-basics.md`.

---

## Phase 7 — Vaultwarden: der eigene Passwort-Manager

**Was machen wir?**
Tailscale-HTTPS aktivieren, Vaultwarden starten, Christinas Account
anlegen, danach die Registrierung wieder schließen.

**Warum?**
Vaultwarden ist der Server für den Passwort-Manager (Bitwarden-App). Er
lauscht nur auf `127.0.0.1` — `tailscale serve` reicht ihn mit einem
echten HTTPS-Zertifikat ins Tailnet weiter. Kein offener Port, kein
selbstsigniertes Zertifikat.

**Befehle**

In der Tailscale-Admin-Konsole: **DNS** → **MagicDNS** und **HTTPS
Certificates** aktivieren.

```bash
cd /srv/docker/vaultwarden && cp .env.example .env
```

`.env` bearbeiten (`nano .env`):

```
SIGNUPS_ALLOWED=true
VW_DOMAIN=https://<maschinenname>.<tailnet>.ts.net
```

(Maschinenname und Tailnet-Name stehen in `tailscale status`.)

> **Wichtig:** Niemals `mkdir data` in diesem Ordner ausführen! Docker
> legt `./data` beim ersten Start selbst an (und muss es dabei sich selbst
> als root gehören lassen) — ein von Hand angelegter Ordner sorgt nur für
> Berechtigungsfehler.

```bash
docker compose up -d
```

```bash
tailscale serve --bg http://127.0.0.1:8081
```

(holt automatisch ein gültiges Zertifikat). Am Mac
`https://<maschinenname>.<tailnet>.ts.net` öffnen und Christinas Account
anlegen — **starkes Master-Passwort**, auf einem Zettel an einem sicheren
Ort notieren (dieses Passwort kann niemand für sie zurücksetzen).

Danach `.env` wieder ändern:

```
SIGNUPS_ALLOWED=false
```

Und erneut:

```bash
docker compose up -d
```

Zum Schluss die Bitwarden-App auf Mac und iPhone installieren, „Selbst
gehostet" wählen, die Server-URL eintragen und anmelden.

**Woran sehen wir, dass es geklappt hat?**
Der Login unter der `https://…ts.net`-Adresse zeigt Christinas Tresor.
Ein zweiter Anmeldeversuch mit neuem Account wird abgelehnt, weil Signups
jetzt aus sind. Die Bitwarden-Apps auf Mac und iPhone zeigen dieselben,
synchronisierten Einträge. Mehr zu Docker-Befehlen: `handbuch/docker-basics.md`.

---

## Phase 8 — Backup: nachts automatisch sichern

**Was machen wir?**
Das Backup-Skript und den systemd-Timer installieren, dann einen
Testlauf machen.

**Warum?**
Ohne Backup ist ein Datenverlust (Serverausfall, Fehlbedienung)
endgültig. Der Timer sichert jede Nacht automatisch — ohne dass jemand
daran denken muss.

**Befehle**

```bash
sudo cp /opt/setup/scripts/backup.sh /usr/local/bin/ && sudo chmod +x /usr/local/bin/backup.sh
sudo cp /opt/setup/scripts/systemd/christina-backup.* /etc/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl enable --now christina-backup.timer
```

Testlauf:

```bash
sudo systemctl start christina-backup.service
ls -lh /srv/backups
cat /var/log/christina-backup.log
```

Gemeinsam anschauen. Danach:

```bash
sudo systemctl list-timers christina-backup.timer
```

**Woran sehen wir, dass es geklappt hat?**
`/srv/backups` enthält frische Dateien (`vaultwarden-<Datum>.tar.gz`, ein
Teleporter-`.zip` von Pi-hole, `configs-<Datum>.tar.gz`). Das Log zeigt
gegen Ende »Backup fertig:« gefolgt von einer Dateiliste, keine Zeile mit
FEHLER oder WARNUNG. `systemctl list-timers` zeigt die nächste Ausführung
um 04:00 Uhr.

---

## Abschluss-Checkliste

Zum gemeinsamen Abhaken, bevor ihr für heute Schluss macht:

- [ ] root-Login per SSH ist zu (`ssh root@<IP>` wird abgelehnt)
- [ ] Passwort-Login per SSH ist zu (nur noch der Schlüssel funktioniert)
- [ ] `ufw` ist aktiv (`ufw status verbose` zeigt „active")
- [ ] SSH über die öffentliche IP läuft ins Leere — nur über Tailscale erreichbar
- [ ] Pi-hole filtert Werbung (Test am iPhone mit aktivem Tailscale)
- [ ] Die Bitwarden-App läuft auf Christinas iPhone und zeigt den Tresor
- [ ] `SIGNUPS_ALLOWED` steht in `stacks/vaultwarden/.env` wieder auf `false`
- [ ] Ein Backup-Testlauf ist erfolgreich gelaufen (Log + `/srv/backups` geprüft)
- [ ] Beide kennen die Handbuch-Dateien und wissen, wo sie liegen:
      `handbuch/mac-basics.md`, `handbuch/linux-basics.md`,
      `handbuch/tailscale.md`, `handbuch/docker-basics.md`,
      `handbuch/notfall.md`
- [ ] Die Tailscale-App ist auf allen Geräten installiert und angemeldet
      (Mac und iPhone von Christina, Mac und iPhone von Markus)
