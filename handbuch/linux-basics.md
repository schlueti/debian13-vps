# Linux-Basics: Die wichtigsten Befehle auf dem Server

Dieses Kapitel ist zum Nachschlagen. Du musst dir nichts davon merken — such
dir hier einfach den Befehl raus, den du gerade brauchst. Alles hier läuft
**auf dem Server**, also nachdem du dich mit `ssh vps` verbunden hast (siehe
`handbuch/mac-basics.md`).

---

## 1. Orientierung: Wo bin ich, was liegt hier rum?

```bash
pwd
```
Zeigt, in welchem Ordner du gerade stehst („print working directory").
Beispiel: `/home/christina`

```bash
ls
```
Zeigt, was in diesem Ordner liegt.
Beispiel: `Downloads  scripts`

```bash
ls -lh
```
Wie `ls`, aber mit Details: Rechte, Größe, Datum. `-h` heißt „human
readable" — Größen als KB/MB statt in Bytes.
Beispiel:
```
drwxr-xr-x 2 christina christina 4,0K Jul 18 10:02 scripts
-rw-r--r-- 1 christina christina  128 Jul 18 09:55 notizen.txt
```

```bash
cd scripts
```
Wechselt in den Ordner `scripts` („change directory").

```bash
cd ..
```
Geht einen Ordner nach oben, zurück Richtung Wurzel.

```bash
cat notizen.txt
```
Gibt den gesamten Inhalt einer Textdatei direkt aus — praktisch für kurze
Dateien.
Beispiel:
```
Server-IP im Router-Menü nachschauen
Backup-Ordner auf dem Mac liegt unter ~/Backups
```

```bash
less notizen.txt
```
Öffnet eine Datei zum Lesen, blättert bei langen Dateien seitenweise.
Beenden mit der Taste `q`.

---

## 2. „Wer bin ich, wo bin ich"

```bash
whoami
```
Zeigt deinen Benutzernamen auf dem Server.
Beispiel: `christina`

```bash
hostname
```
Zeigt den Namen des Servers selbst — nützlich, wenn du mal an mehreren
Maschinen gleichzeitig arbeitest, um sicherzugehen, wo du gerade bist.
Beispiel: `vps`

---

## 3. sudo: kurz Chef sein

Manche Befehle verändern Dinge, die allen Benutzern gehören (System-Updates,
Neustart) — die darfst du nicht einfach so ausführen. Stellst du dem Befehl
`sudo` voran, darfst du das für diesen einen Befehl trotzdem, **wenn** du
dein eigenes Passwort bestätigst. `sudo` fragt also nach **deinem**
Passwort (dem, mit dem du dich einloggst), nicht nach einem geheimen
Admin-Passwort. Man kann sich das vorstellen wie: kurz Chef sein, einen
Befehl ausführen, danach wieder normaler Benutzer.

---

## 4. Updates selbst anstoßen

```bash
sudo apt update
```
Holt nur die **Liste** verfügbarer Updates vom Debian-Server — installiert
noch nichts.

```bash
sudo apt upgrade
```
Installiert die Updates aus dieser Liste tatsächlich.

Der Unterschied in einem Satz: `update` schaut nach, was es Neues gibt,
`upgrade` installiert es.

**Wichtig:** Sicherheitsupdates macht der Server dank `unattended-upgrades`
nachts automatisch — dafür musst du selbst nichts tun. `apt update` /
`upgrade` brauchst du nur, wenn du mal von Hand nachschauen oder etwas
Bestimmtes aktualisieren willst.

---

## 5. Dienste: läuft er noch?

```bash
systemctl status ssh
```
Zeigt, ob der SSH-Dienst (die Verbindung, mit der du gerade eingeloggt
bist) läuft.

```bash
systemctl status docker
```
Zeigt, ob Docker läuft — Docker muss laufen, damit Pi-hole und Vaultwarden
funktionieren.

So liest du die Ausgabe: Steht dort **`active (running)`**, meist grün
markiert, läuft der Dienst — alles gut. Beispiel:
```
● docker.service - Docker Application Container Engine
     Loaded: loaded (/lib/systemd/system/docker.service; enabled)
     Active: active (running) since Mon 2026-07-13 03:12:04 CEST; 6 days ago
```
Beenden mit `q`, falls die Ausgabe im Blätter-Modus hängen bleibt.

---

## 6. Logs: was ist passiert?

```bash
journalctl -u docker --since today
```
Zeigt alle Log-Meldungen des Docker-Dienstes seit Mitternacht — nützlich,
um zu prüfen, was heute passiert ist.
Beispiel:
```
Jul 19 03:12:04 vps dockerd[512]: time="..." msg="Container abc123 started"
Jul 19 03:12:05 vps dockerd[512]: time="..." msg="Container def456 started"
```

```bash
journalctl -f
```
Zeigt Log-Meldungen live, während sie passieren („follow") — es kommen
laufend neue Zeilen dazu, solange etwas passiert. Beenden mit `Ctrl`+`C`.
Beispiel:
```
Jul 19 14:02:11 vps dockerd[512]: time="..." msg="..."
Jul 19 14:02:13 vps dockerd[512]: time="..." msg="..."
```

Für die einzelnen Container (Pi-hole, Vaultwarden) gibt es einen eigenen,
einfacheren Befehl — siehe `handbuch/docker-basics.md`.

---

## 7. Platz & Speicher

```bash
df -h /
```
Zeigt, wie viel Speicherplatz auf der Festplatte noch frei ist. `-h` wieder
„human readable".
Beispiel:
```
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        20G  6,1G   13G  33% /
```

```bash
free -h
```
Zeigt, wie viel Arbeitsspeicher (RAM) belegt und frei ist.
Beispiel:
```
               total        used        free      shared  buff/cache   available
Mem:           2,0Gi       850Mi       340Mi        12Mi       850Mi       1,0Gi
```

---

## 8. Neustart

```bash
sudo reboot
```
Startet den Server komplett neu. Die SSH-Verbindung bricht dabei sofort ab
— das ist normal, kein Fehler.

Danach **1–2 Minuten Geduld**: Der Server braucht etwas Zeit zum
Hochfahren, bevor SSH, Tailscale und die Container wieder erreichbar sind.
Einfach kurz warten und dann erneut `ssh vps` versuchen.

Falls danach etwas nicht wie erwartet aussieht: `handbuch/notfall.md`.
