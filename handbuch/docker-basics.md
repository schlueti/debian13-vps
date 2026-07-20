# Docker-Basics: Container, Logs, Neustart, Updates

Dieses Kapitel ist zum Nachschlagen, wenn du mit Pi-hole oder Vaultwarden
arbeiten willst. Alles hier läuft **auf dem Server** (`ssh vps`). Du bist
dort Mitglied der Docker-Gruppe und Eigentümerin der Ordner unter
`/srv/docker` — du brauchst für die Befehle unten also **kein** `sudo`.
Ausnahme: die Daten-Unterordner darin (z. B. `vaultwarden/data`) legt
Docker beim ersten Start selbst an, die gehören `root` — die lässt du
einfach in Ruhe, nicht von Hand anfassen.

---

## 1. Was ist ein Container eigentlich?

Ein Container ist wie ein Fertiggericht: alles, was das Programm zum
Laufen braucht, ist schon abgepackt drin — Christina muss nichts extra
installieren. Er ist außerdem isoliert von der restlichen Küche: Was im
Container passiert, betrifft nicht den Rest des Servers, und umgekehrt.
Pi-hole, Unbound und Vaultwarden laufen deshalb jeweils in ihrem eigenen
Container, unabhängig voneinander.

---

## 2. Laufen die Container? `docker ps`

```bash
docker ps
```
Zeigt alle **laufenden** Container.

Beispiel:
```
CONTAINER ID   IMAGE                       NAMES         STATUS
a1b2c3d4e5f6   vaultwarden/server:1.36.0   vaultwarden   Up 3 days
f6e5d4c3b2a1   pihole/pihole:2026.07.2     pihole        Up 3 days
```

Die wichtigsten Spalten:
- **NAMES** — der Name des Containers, z. B. `pihole`, `unbound`,
  `vaultwarden`. Den brauchst du für die Befehle weiter unten.
- **STATUS** — `Up 3 days` heißt: läuft seit 3 Tagen ohne Unterbrechung,
  alles gut. Steht dort stattdessen `Restarting` oder gar kein Eintrag für
  den Container, stimmt etwas nicht.

In Wirklichkeit siehst du noch mehr Spalten (COMMAND, CREATED, PORTS) —
wichtig für dich sind vor allem NAMES und STATUS.

---

## 3. Logs ansehen

```bash
docker logs pihole --tail 50
```
Zeigt die letzten 50 Zeilen der Log-Ausgabe von Pi-hole — nützlich, um zu
sehen, was der Container zuletzt gemacht hat oder ob eine Fehlermeldung
auftaucht.

```bash
docker logs vaultwarden --tail 50
```
Dasselbe für Vaultwarden.

---

## 4. Wo liegen meine Daten?

- Pi-hole: `/srv/docker/pihole`
- Vaultwarden: `/srv/docker/vaultwarden`

Das ist der wichtigste Merksatz zu Docker überhaupt: **Container sind
wegwerfbar, die Ordner sind das Wertvolle.** Ein Container lässt sich
jederzeit löschen und neu starten, ohne dass etwas verloren geht — solange
diese Ordner erhalten bleiben. Backups betreffen deshalb genau diese
Ordner, nicht die Container selbst.

---

## 5. Einen Dienst neu starten

```bash
cd /srv/docker/pihole && docker compose restart
```
Startet Pi-hole (und Unbound) neu, ohne etwas an den Daten zu verändern.
Für Vaultwarden entsprechend mit `cd /srv/docker/vaultwarden`.

---

## 6. Updates

Die Image-Versionen sind in den `docker-compose.yml`-Dateien **fest
gepinnt** (z. B. `vaultwarden/server:1.36.0`) — das ist Absicht, damit sich
nichts von selbst und unbemerkt verändert. Das bedeutet aber auch:
`docker compose pull` allein aktualisiert **nichts**, solange die
Versionsnummer in der Datei gleich bleibt.

Ein Update läuft deshalb in zwei Schritten:

1. Die Versionsnummer in `docker-compose.yml` erhöhen (das macht am Anfang
   Markus, bis du dich sicherer fühlst).
2. Dann:
   ```bash
   cd /srv/docker/vaultwarden && docker compose pull && docker compose up -d
   ```
   `pull` lädt das neue Image herunter, `up -d` startet den Container damit
   neu (`-d` = im Hintergrund, „detached").

Gleiches Prinzip für Pi-hole/Unbound, nur mit `cd /srv/docker/pihole`.

---

## 7. Aufräumen

```bash
docker image prune -a -f
```
Löscht alte, nicht mehr benutzte Image-Versionen (z. B. nach einem Update
übrig gebliebene) und schafft damit Platz auf der Festplatte. `-a` entfernt
alle Images, die kein Container mehr benutzt — nach einem Update also die
alte Version; ohne `-a` würde bei uns nichts passieren, weil unsere Images
feste Versionsnummern (Tags) haben und die alte Version dadurch getaggt
bleibt statt „dangling" zu werden. `-f` heißt „force" — es wird ohne
Rückfrage gelöscht, aber es betrifft nur ungenutzte Images, nie laufende
Container oder deine Daten in `/srv/docker`.

---

Wenn ein Container nach einem dieser Schritte nicht wieder hochkommt:
`handbuch/notfall.md`.
