# Tailscale: der private Tunnel zu deinem Server

Dieses Kapitel gehört zu Phase 4 im `runbook.md`. Es erklärt, was
Tailscale eigentlich ist und wie du im Alltag erkennst, ob es läuft —
das ist der häufigste Grund, warum mal „etwas nicht geht" (siehe auch
`handbuch/notfall.md`).

---

## 1. Was ist ein Tailnet?

Ein Tailnet ist dein privates Netz aus genau deinen eigenen Geräten —
Mac, iPhone und der Server. Stell es dir vor wie einen unsichtbaren
Tunnel, der zwischen diesen Geräten aufgespannt ist: Was durch den
Tunnel läuft, sehen nur die Geräte, die auch drin sind. Für den Rest des
Internets ist der Tunnel unsichtbar und nicht erreichbar.

---

## 2. Warum brauchen wir das?

Der Server hat zwar eine öffentliche Adresse im Internet (die hat jeder
Server bei einem Hoster) — aber seit Phase 5 im Runbook ist von außen
nichts mehr erreichbar. SSH, Pi-hole und Vaultwarden laufen nur noch
durch den Tailscale-Tunnel. Das heißt: Ohne Tailscale kein Zugriff —
weder für dich, noch für jemanden von außen.

---

## 3. Die App auf dem Mac

Nach der Installation sitzt ein kleines Tailscale-Symbol in der
Menüleiste oben rechts (neben Uhrzeit, WLAN-Symbol etc.). Draufklicken
zeigt dir:

- **Verbunden** — meist ein ausgefülltes/farbiges Symbol, im Menü steht
  „Connected" o. ä.
- **Getrennt** — das Symbol wirkt ausgegraut, im Menü steht „Connect"
  o. ä. — draufklicken, um dich wieder zu verbinden.

Im selben Menü findest du auch eine **Geräteliste**: alle Geräte in
eurem Tailnet, also Mac, iPhone und der Server.

---

## 4. Die App am iPhone

Am iPhone zeigt ein **VPN-Symbol** oben in der Statuszeile (neben
Akku/Uhrzeit), ob Tailscale aktiv ist. Ist es weg, ist Tailscale
getrennt.

**Wichtig:** Die Tailscale-App muss aktiv verbunden sein, sonst
funktionieren zwei Dinge nicht:

- Der Werbefilter über Pi-hole (DNS läuft nur durchs Tailnet).
- Bitwarden/Vaultwarden (der Server ist ohne Tailscale gar nicht
  erreichbar).

Merksatz für unterwegs: Wenn am iPhone plötzlich etwas nicht geht, ist
das fast nie ein Internetproblem — die erste Frage ist immer: **„Ist
Tailscale an?"**

---

## 5. Die Admin-Konsole: login.tailscale.com

Unter [login.tailscale.com](https://login.tailscale.com) (im Browser,
mit eurem Tailscale-Account anmelden) verwaltet ihr das ganze Tailnet
von außen:

- **Geräteliste** — alle Geräte, die aktuell im Tailnet sind, inklusive
  wann sie zuletzt online waren.
- **Gerät hinzufügen** — kein Klick in der Konsole nötig: einfach die
  Tailscale-App auf dem neuen Gerät installieren und mit demselben
  Account anmelden, dann taucht es automatisch in der Liste auf.
- **Gerät entfernen** — Gerät in der Liste anklicken, dann „Remove" o. ä.
  wählen. Das Gerät verliert danach sofort den Zugriff aufs Tailnet.

---

## 6. Der DNS-Eintrag

In der Admin-Konsole unter **DNS → Nameserver** steht die Tailscale-IP
des Servers eingetragen (mit aktiviertem „Override local DNS"). Das
bedeutet: Jedes Gerät im Tailnet schickt seine DNS-Anfragen — also die
Frage „wie lautet die Adresse zu dieser Webseite?" — automatisch an den
Pi-hole auf dem Server. Deshalb wirkt der Werbefilter auf Mac und iPhone
gleichermaßen, ohne dass du an den Geräten selbst etwas einstellen
musst.

---

## 7. Key-Expiry: warum der Server nicht rausfällt

Normalerweise verlangt Tailscale, dass sich jedes Gerät nach einigen
Monaten neu anmeldet (der „Schlüssel" läuft ab). Für ein Handy oder
einen Laptop ist das kein Problem — für einen Server, der einfach
durchlaufen soll, wäre das lästig.

Markus hat deshalb für die VPS-Maschine in der Admin-Konsole (Gerät
anklicken → „…" → **„Disable key expiry"**) das Ablaufen des Schlüssels
abgeschaltet. Das bedeutet: Der Server bleibt dauerhaft im Tailnet,
ohne dass sich jemand alle paar Monate erneut anmelden muss. Das ist im
Runbook Phase 4 als fester Schritt vorgesehen — falls der Server
trotzdem mal aus der Geräteliste verschwindet, ist das der erste Punkt,
den man mit Markus prüft.

Diese Ausnahme gilt nur für den Server. Deine eigenen Geräte (Mac,
iPhone) melden sich ganz normal etwa alle 6 Monate ab — die App fragt
dann nach einem Login statt sich einfach zu verbinden. Das ist kein
Fehler: einfach mit demselben Tailscale-Account wieder anmelden, dann
funktioniert alles wie vorher.
