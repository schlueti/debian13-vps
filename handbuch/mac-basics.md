# Mac-Basics: Terminal, SSH-Key, Verbindung zum Server

Dieses Kapitel gehört zu Phase 0 im `runbook.md` — du machst es **daheim,
allein, vor dem Einrichtungs-Nachmittag**. Danach hast du deinen eigenen
SSH-Key — und weißt für später, wie du dich mit dem Server verbindest.

Ein SSH-Key ist wie ein Haustürschlüssel, nur digital: Er besteht aus zwei
Dateien, einem privaten und einem öffentlichen Teil. Der Server bekommt nur
den öffentlichen Teil (das Türschloss) und lässt danach nur noch Leute mit
dem passenden privaten Schlüssel herein.

---

## 1. Terminal öffnen

Das Terminal ist ein Textfenster, in dem du dem Computer direkt Befehle
gibst — statt zu klicken, tippst du.

1. `Cmd` + `Leertaste` drücken (öffnet Spotlight, die Suche).
2. „Terminal" tippen.
3. `Enter` drücken.

Es öffnet sich ein schwarzes oder weißes Fenster mit einer Eingabezeile.
Dort tippst du ab jetzt die Befehle rein.

---

## 2. SSH-Key erzeugen

Im Terminal eintippen und mit `Enter` bestätigen:

```bash
ssh-keygen -t ed25519 -C "christina@mac"
```

- `-t ed25519`: das Verschlüsselungsverfahren — modern und sicher.
- `-C "christina@mac"`: nur ein Kommentar, damit du später erkennst, von
  welchem Gerät der Key stammt. Hat keine technische Funktion.

Jetzt stellt `ssh-keygen` dir zwei Fragen:

**„Enter file in which to save the key (…/id_ed25519):"**
Einfach `Enter` drücken. Das übernimmt den Standard-Speicherort — den
brauchst du nicht zu ändern.

**„Enter passphrase (empty for no passphrase):"**
Eine Passphrase ist **empfohlen**. Sie ist das „Passwort für den Schlüssel":
Selbst wenn jemand deinen Mac klaut, kommt er ohne diese Passphrase nicht an
deinen privaten Schlüssel. Tipp dir eine Passphrase aus, die du dir merken
kannst, und bestätige sie danach noch einmal. Die Zeichen erscheinen beim
Tippen nicht im Terminal — das ist normal, kein Fehler. Falls die beiden
Eingaben nicht übereinstimmen, fragt `ssh-keygen` einfach noch einmal neu —
nichts ist kaputt, einfach beide Male nochmal eintippen.

Danach zeigt das Terminal eine kleine grafische „Fingerabdruck"-Zeichnung.
Das ist nur eine Bestätigung, dass der Key erstellt wurde — die kannst du
ignorieren.

**Wichtig:** Es sind jetzt zwei Dateien entstanden:

- `~/.ssh/id_ed25519` — der **private** Schlüssel. Der bleibt **immer** auf
  deinem Mac. Niemals kopieren, niemals weiterschicken, niemals in ein Repo
  einchecken.
- `~/.ssh/id_ed25519.pub` — der **öffentliche** Schlüssel. Nur diese Datei
  wird weitergegeben.

---

## 3. Public Key anzeigen und kopieren

Anzeigen:

```bash
cat ~/.ssh/id_ed25519.pub
```

Das gibt eine einzelne lange Zeile aus, die mit `ssh-ed25519` beginnt.

In die Zwischenablage kopieren, ohne ihn manuell markieren zu müssen:

```bash
pbcopy < ~/.ssh/id_ed25519.pub
```

Jetzt ist der Key in der Zwischenablage — du kannst ihn mit `Cmd`+`V`
überall einfügen (z. B. beim Speichern als `scripts/keys/christina.pub` im
Repo, siehe `runbook.md` Phase 0).

---

> **Ab hier: erst am/nach dem Einrichtungs-Nachmittag!** Die Kapitel 4–6
> funktionieren erst, wenn dein Benutzer auf dem Server existiert (Phase 1
> im Runbook) — vorher gibt es den User `christina` auf dem Server noch
> nicht, die Verbindung kann also noch nicht klappen. Für die Vorbereitung
> (Phase 0) bist du nach Kapitel 3 fertig.

## 4. `~/.ssh/config` einrichten

Mit dieser Datei reicht später `ssh vps` statt der ganzen Adresse.

Datei öffnen (falls sie noch nicht existiert, wird sie neu angelegt):

```bash
nano ~/.ssh/config
```

**nano-Grundlagen**, falls dir der Editor unbekannt ist: Du tippst einfach
Text ein wie in einem normalen Textfeld. Zum Speichern und Beenden:

- `Ctrl`+`O` — speichern („O" wie „Output"), danach `Enter` bestätigen.
- `Ctrl`+`X` — Editor beenden.

Folgendes eintippen:

```
Host vps
    HostName <VPS-IP>
    User christina
    IdentityFile ~/.ssh/id_ed25519
    UseKeychain yes
    AddKeysToAgent yes
```

Die letzten beiden Zeilen sorgen dafür, dass macOS die Passphrase im
Schlüsselbund nachschlägt, statt sie jedes Mal neu abzufragen — mehr dazu
in Kapitel 6.

Ersetze `<VPS-IP>` durch die öffentliche IP-Adresse, die ihr vom Hoster
bekommen habt (steht meist in der Bestätigungsmail).

> **Später aktualisieren:** Nach Phase 4/5 im Runbook ist der Server nur
> noch über Tailscale erreichbar, die öffentliche IP funktioniert dann
> nicht mehr für SSH. Sobald ihr die Tailscale-IP kennt (`tailscale ip -4`
> auf dem Server), öffnest du diese Datei noch einmal mit `nano
> ~/.ssh/config` und ersetzt die `HostName`-Zeile durch die Tailscale-IP.
> Bis dahin bleibt hier einfach die öffentliche IP stehen.

---

## 5. Verbinden

Jetzt testen:

```bash
ssh vps
```

Beim allerersten Verbindungsversuch zu einem Server fragt SSH einmalig:

> „The authenticity of host '…' can't be established … Are you sure you
> want to continue connecting (yes/no)?"

Das ist normal — SSH kennt diesen Server noch nicht und fragt zur
Sicherheit nach. Mit `yes` bestätigen und `Enter` drücken. Diese Frage
kommt danach nicht mehr, außer der Server ändert sich grundlegend.

Falls du eine Passphrase gesetzt hast, fragt SSH jetzt danach — das ist die
Passphrase aus Schritt 2, nicht das sudo-Passwort vom Server.

**Problem: SSH fragt trotz Key nach dem Passwort.** Wenn im Terminal eine
Warnung wie „Permissions 0644 for '…/id_ed25519' are too open … This private
key will be ignored" steht, sind die Zugriffsrechte deines **privaten**
Schlüssels zu offen — SSH benutzt ihn dann aus Sicherheitsgründen nicht und
fällt aufs Passwort zurück. Einmalig korrigieren:

```bash
chmod 600 ~/.ssh/id_ed25519
```

Danach `ssh vps` erneut versuchen. (Das ist ein Mac-Problem, nicht der
Server — am Server muss dafür nichts geändert werden.)

---

## 6. Schlüsselbund: Passphrase merken lassen

Damit du die Passphrase nicht bei jeder Verbindung erneut eintippen musst,
kann macOS sie im Schlüsselbund speichern:

```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

Das speichert die Passphrase im macOS-Schlüsselbund. Dass sie danach auch
bei jedem Terminal-Neustart automatisch geladen wird, übernehmen die beiden
Zeilen `UseKeychain yes` und `AddKeysToAgent yes`, die du in Kapitel 4 in
`~/.ssh/config` eingetragen hast. Der private Schlüssel selbst verlässt
dabei nie deinen Mac, nur die Passphrase liegt jetzt sicher im
Schlüsselbund.
