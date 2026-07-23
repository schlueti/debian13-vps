# Deine Anleitung: Werbeblocker & Passwort-Tresor

Hallo Christina! 👋 Markus hat dir zwei Dinge eingerichtet, die auf all deinen
Geräten (und denen deiner Familie) laufen:

1. **Pi-hole** — ein Werbeblocker fürs ganze Handy/Tablet/Mac, nicht nur im Browser.
2. **Vaultwarden** — dein eigener Passwort-Tresor (wie ein digitaler Schlüsselbund).

Beides läuft über **Tailscale** — das ist eine kleine App, die deine Geräte mit
dem Server verbindet. **Merksatz für alles hier: Solange Tailscale an ist,
funktioniert es. Ist Tailscale aus, funktioniert es nicht.** Das ist zu 90 % die
Antwort, falls mal „was nicht geht".

Du musst nichts von dem hier verstehen — nur den Schritten folgen. 🙂

---

> ## 🔧 Nur für Markus — vor dem Weitergeben ausfüllen
>
> Diese Werte einmal eintragen und diesen Kasten dann löschen:
>
> - **Pi-hole-Adresse (Tailscale-IP):** `100.x.x.x` → per `tailscale ip -4`
> - **Pi-hole-Admin-Seite:** `http://100.x.x.x:8080/admin`
> - **Pi-hole-Passwort:** `________`
> - **Vaultwarden-Adresse:** `https://<maschine>.<tailnet>.ts.net` → aus `tailscale status`
> - **Einladungs-Link für Familie:** (in der Tailscale-Konsole erzeugen, siehe unten)
>
> Überall unten stehen diese Platzhalter — einmal durch die echten Werte ersetzen.

---

## Teil 1 — Tailscale: die Verbindung

Tailscale ist schon auf deinem Mac und iPhone installiert und angemeldet. Du
erkennst es hier:

- **Am Mac:** oben rechts in der Menüleiste (neben Uhr und WLAN) sitzt ein kleines
  Tailscale-Symbol. Ist es farbig/ausgefüllt → verbunden. Ist es blass/grau →
  draufklicken und **„Connect"** wählen.
- **Am iPhone:** die Tailscale-App öffnen. Oben steht ein Schalter — der muss auf
  **grün/an** stehen.

Mehr musst du im Alltag nicht tun. Die App läuft leise im Hintergrund und braucht
kaum Akku.

---

## Teil 2 — Die Verwaltungs-Seite (ein paar einmalige Einstellungen)

Es gibt eine Verwaltungs-Seite im Internet, auf der die Geräte und Einstellungen
verwaltet werden: **[login.tailscale.com](https://login.tailscale.com)** — dort mit
deinem Tailscale-Konto anmelden (dasselbe, mit dem die App angemeldet ist).

Was du dort siehst: eine **Liste deiner Geräte** (Mac, iPhone, der Server, später
die Geräte deiner Familie). Grüner Punkt = online. **Im Alltag schaust du hier nie
rein.** Es gibt nur ein paar **einmalige** Aufgaben, die hier erledigt werden:
den Werbeblocker einschalten (gleich unten), Familie einladen (Teil 4) und für
Markus einen Zugangs-Schlüssel erstellen (Teil 5).

### ✅ Einmalig einschalten: Werbeblocker fürs ganze Netz (wichtig!)

Damit der Werbeblocker auf allen Geräten wirkt, muss er einmal in der
Verwaltungs-Seite aktiviert werden. **Ohne diesen Schritt passiert noch nichts** —
also bitte einmal machen (dauert 1 Minute):

1. Auf **[login.tailscale.com](https://login.tailscale.com)** anmelden.
2. Oben in der Menüleiste auf **„DNS"** klicken.
3. Beim Abschnitt **„Nameservers"** auf **„Add nameserver"** → **„Custom…"** klicken.
4. Als Adresse die Pi-hole-Adresse eintragen: **`100.x.x.x`** (die IP von oben,
   ohne `http` und ohne `:8080`) → **Save/Speichern**.
5. Jetzt erscheint eine Option **„Override local DNS"** — den Schalter auf **an**
   stellen. (Das sorgt dafür, dass wirklich alle Geräte den Werbeblocker nehmen.)

Fertig. Ab jetzt filtert Pi-hole für alle Geräte im Netz. Wenn Markus dir das schon
abgenommen hat, kannst du diesen Schritt überspringen.

---

## Teil 3 — Der Werbeblocker (Pi-hole)

**Das Beste zuerst: Im Alltag musst du dafür nichts tun.** Sobald der Werbeblocker
einmal eingeschaltet ist (Teil 2) und Tailscale an ist, ist er automatisch für all
deine Geräte aktiv. Werbung verschwindet in Apps und im Browser von selbst.

**Kurzer Test, ob's wirkt:** Öffne eine werbelastige Nachrichten-Seite (z. B. eine
Boulevard-Zeitung). Wo sonst Werbebanner blinken, ist jetzt Ruhe oder eine leere
Fläche. 🎉

**Die Pi-hole-Seite** (optional, nur wenn's dich interessiert): im Browser
`http://100.x.x.x:8080/admin` öffnen, Passwort ist `________`. Du siehst dort ein
Dashboard mit bunten Zahlen: wie viele Anfragen geblockt wurden usw. **Nett zum
Angucken, aber völlig egal für den Alltag** — du kannst die Seite ignorieren.

**Falls mal eine Seite kaputt aussieht** (etwas wird fälschlich blockiert): sag
Markus Bescheid, er trägt die Seite in eine Ausnahmeliste ein. Bitte nicht selbst
dran rumstellen.

---

## Teil 4 — Familie mitnehmen 👨‍👩‍👧‍👦

Deine Familie kann denselben Werbeblocker nutzen. Dafür müssen ihre Geräte in dein
Tailscale-Netz. Das läuft in zwei Schritten:

### Schritt A — Du lädst sie ein (einmalig, pro Person)

1. Geh auf **[login.tailscale.com](https://login.tailscale.com)** und melde dich an.
2. Links im Menü auf **„Users"** klicken.
3. Oben rechts den Knopf **„Invite users"** (Nutzer einladen) klicken.
4. Es erscheint ein **Einladungs-Link**. Den kannst du kopieren und per WhatsApp/
   Mail an die Person schicken. (Oder direkt die E-Mail-Adresse eintragen — dann
   verschickt Tailscale die Einladung selbst.)
5. Fertig. Diesen Schritt für jede Person einmal machen.

> Markus kann den Einladungs-Link auch vorab erzeugen und dir hier reinschreiben:
> **Einladungs-Link:** `________`

### Schritt B — Was deine Familie tun muss

Schick ihnen am besten genau diese kleine Anleitung:

> **So machst du beim Werbeblocker mit:**
> 1. Installiere die App **„Tailscale"** aus dem App Store (iPhone/iPad),
>    Play Store (Android) oder von **tailscale.com/download** (Mac/Windows).
> 2. Öffne den **Einladungs-Link**, den du von Christina bekommen hast, und
>    **melde dich an** (du kannst dich einfach mit deinem Google- oder
>    Apple-Konto anmelden, kein neues Passwort nötig).
> 3. Stell in der Tailscale-App den Schalter auf **an (grün)**.
> 4. **Das war's.** Werbung wird ab jetzt auf deinem Gerät automatisch geblockt,
>    solange Tailscale an ist. Du musst nichts einstellen.

Deine Familie muss **nichts** über DNS, Server oder Einstellungen wissen — der
Werbeblocker wird ihren Geräten automatisch mitgegeben, sobald sie im Netz sind.

> Hinweis zur Privatsphäre, falls jemand fragt: Ihr seht in der Geräteliste nur die
> **Gerätenamen**, nicht was die Person surft oder tut. Der Inhalt bleibt privat.

---

## Teil 5 — Für Markus: einen Zugangs-Schlüssel (Auth Key) ausstellen 🔑

Markus möchte sich mit seinem eigenen Rechner in dein Netz einklinken, ohne sich
jedes Mal über die Webseite anmelden zu müssen. Dafür stellst du ihm einen
**Zugangs-Schlüssel** aus — das ist wie ein Einmal-Passwort, mit dem sich sein
Gerät selbst anmeldet. So geht's:

1. Auf **[login.tailscale.com](https://login.tailscale.com)** anmelden.
2. Oben rechts auf **„Settings"** (Einstellungen) klicken.
3. Links im Menü auf **„Keys"** (Schlüssel) klicken.
4. Den Knopf **„Generate auth key…"** (Schlüssel erzeugen) klicken.
5. Bei **„Description"** etwas Erkennbares eintragen, z. B. `Markus Rechner`.
6. **Markus sagt dir, ob du den Schalter „Reusable" (mehrfach verwendbar)
   anhaken sollst** — vermutlich ja, dann kann er sich immer wieder damit
   verbinden. Den Rest (Ablaufdatum usw.) so lassen.
7. Auf **„Generate key"** klicken. Es erscheint ein langer Text, der mit
   **`tskey-auth-…`** anfängt.

> ⚠️ Dieser Schlüssel wird **nur ein einziges Mal angezeigt** — also gleich
> kopieren. Und: Er ist wie ein Passwort. Schick ihn Markus bitte **nicht per
> normaler Mail/WhatsApp**, sondern sicher — am einfachsten legst du ihn als
> Eintrag in eurem **Passwort-Tresor** (Teil 6) ab, oder gibst ihn ihm persönlich.

Wenn Markus sich damit verbunden hat, taucht sein Rechner in deiner Geräteliste
auf — fertig. Den Schlüssel selbst braucht danach niemand mehr.

---

## Teil 6 — Der Passwort-Tresor (Vaultwarden)

Das ist dein persönlicher, sicherer Speicher für Passwörter. Er läuft auf deinem
eigenen Server — die Passwörter liegen also bei dir, nicht bei einer fremden Firma.

### So erreichst du ihn

Im Browser diese Adresse öffnen:

**`https://<maschine>.<tailnet>.ts.net`**  ← (Markus trägt die echte Adresse ein)

Wichtig: Immer **genau diese Adresse** benutzen (mit `https://` vorne). Weil sie ein
echtes Sicherheits-Zertifikat hat, zeigt dein Browser ein **Schloss-Symbol** und
**keine Warnung** — alles korrekt und verschlüsselt. Falls doch mal eine
Zertifikats-Warnung käme: Du bist wahrscheinlich auf der falschen Adresse (z. B.
über eine IP statt dieser `.ts.net`-Adresse) — dann einfach nochmal die richtige
Adresse oben nehmen.

### Dein Konto anlegen (einmalig)

1. Die Adresse oben öffnen.
2. Auf **„Create account" / „Konto erstellen"** klicken.
3. E-Mail eintragen und ein **Master-Passwort** vergeben.

> ⚠️ **Ganz wichtig — bitte ernst nehmen:** Dieses **Master-Passwort kann niemand
> zurücksetzen**, auch Markus nicht. Wenn du es vergisst, sind alle gespeicherten
> Passwörter weg. Schreib es dir auf einen **Zettel** und leg ihn an einen sicheren
> Ort (z. B. zu wichtigen Dokumenten). Nimm ein Passwort, das lang, aber für dich
> merkbar ist — z. B. drei zufällige Wörter mit einer Zahl.

### Im Alltag benutzen

Am bequemsten mit der **Bitwarden-App** (Vaultwarden ist damit kompatibel):

1. **„Bitwarden"** aus dem App Store / Play Store installieren.
2. Beim ersten Start auf **„Selbst gehostet" / „Self-hosted"** umstellen (meist ein
   kleines Zahnrad oder „Region/Server" oben) und dort die Adresse
   `https://<maschine>.<tailnet>.ts.net` eintragen.
3. Mit E-Mail und deinem Master-Passwort anmelden.

Es gibt auch eine **Bitwarden-Erweiterung** für den Browser (Chrome/Safari/Firefox)
— die füllt Passwörter auf Webseiten automatisch aus. Sehr praktisch, gleiche
Anmeldung wie in der App.

**Auch hier gilt:** Tailscale muss an sein, sonst ist der Tresor nicht erreichbar.

---

## Teil 7 — Wenn mal etwas nicht geht

Fast immer ist es dasselbe: **Tailscale ist aus.** Also zuerst prüfen:

- Mac: Symbol oben rechts farbig? Sonst „Connect".
- iPhone: Tailscale-App auf, Schalter grün?

Wenn Tailscale an ist und es klemmt trotzdem: **Markus fragen.** Nichts selbst an
Einstellungen ändern — kaputt machen kannst du nichts, aber Markus findet es
schneller, wenn nichts verstellt wurde.

---

## Kurz-Spickzettel 📌

| Was | Wie |
|-----|-----|
| Läuft alles? | Tailscale an (Mac: Symbol farbig / iPhone: Schalter grün) |
| Werbeblocker einschalten | Einmalig: login.tailscale.com → DNS → Nameserver `100.x.x.x` + „Override local DNS" an |
| Werbeblocker im Alltag | Läuft automatisch, nichts zu tun |
| Familie einladen | login.tailscale.com → Users → Invite users → Link schicken |
| Schlüssel für Markus | login.tailscale.com → Settings → Keys → Generate auth key |
| Passwort-Tresor | `https://<maschine>.<tailnet>.ts.net` oder Bitwarden-App |
| Master-Passwort | Auf Zettel notieren — kann NIEMAND zurücksetzen! |
| Etwas geht nicht | Erst Tailscale prüfen, dann Markus |

Viel Spaß damit! ✨
