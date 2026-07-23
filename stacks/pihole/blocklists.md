# Pi-hole Blocklisten (Deutschland-Fokus)

Kuratierte Adlists für dieses Pi-hole. Quelle der deutschen Listen:
[RPiList/specials](https://github.com/RPiList/specials) — aktiv gepflegtes
deutsches Projekt (Werbung, Fakeshops, Phishing, Banken-Schutz).

## Einbinden

Web-UI → **Lists** → URL bei „Add a new adlist" einfügen → **Add**.
Nach dem Hinzufügen/Ändern immer die Gravity-DB neu bauen, sonst greift nichts:

```bash
docker exec pihole pihole -g          # Gravity aktualisieren (zieht alle Listen)
```

RPiList aktualisiert die Listen laufend — ein wöchentliches `pihole -g` per
Cron/Timer hält sie frisch (Pi-hole macht das per Default schon einmal die Woche).

---

## Basis (weltweit, ist Pi-hole-Default)

Kommt bei einer frischen Installation schon mit — hier nur zur Referenz:

```
https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
```

## Empfohlen (Deutschland) — Werbung, Betrug, Malware

```
https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/easylist
https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/notserious
https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/malware
https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/Phishing-Angriffe
https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/spam.mails
https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/crypto
```

| Liste             | Blockt                                                    |
|-------------------|-----------------------------------------------------------|
| easylist          | Werbung (erweiterte deutsche EasyList)                    |
| notserious        | Fakeshops & Abzocker                                      |
| malware           | Schadsoftware-Domains                                     |
| Phishing-Angriffe | Phishing der letzten 30 Tage                              |
| spam.mails        | In Spam-Mails verteilte Domains                           |
| crypto            | Cryptomining im Browser                                   |

## Banken- & Marken-Schutz (Typosquatting) — optional, sehr große Listen

Schützt vor vertippten Banken-/Marken-Domains. Riesig (~1 Mio. Zeilen je Datei),
nur nehmen, wenn RAM/Performance reicht:

```
https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/DomainSquatting1
https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/DomainSquatting2
https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/DomainSquatting3
https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/DomainSquatting4
```

## Telemetrie — optional

```
https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/Win10Telemetry
https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/MS-Office-Telemetry
https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/samsung
```

## Familien-/Jugendschutz — optional (kann überblocken)

```
https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/gambling
https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/pornblock1
https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/DatingSites
```

Weitere Kategorien (pornblock2–6, child-protection, Streaming, Corona-Blocklist,
Fake-Science): siehe [RPiList Blocklisten.md](https://github.com/RPiList/specials/blob/master/Blocklisten.md).

---

**Zu viel geblockt?** Web-UI → **Domains** → Domain als Allow eintragen,
danach `docker exec pihole pihole -g`. Query Log zeigt, welche Liste geblockt hat.
