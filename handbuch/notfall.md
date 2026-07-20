# Notfall-Checkliste

Diese Liste ist so sortiert: häufige, harmlose Probleme zuerst, seltene
zuletzt. Arbeite sie **von oben nach unten** durch und brich ab, sobald
ein Schritt das Problem löst. Die Schritte sind durchnummeriert, damit
du Markus am Telefon einfach die Nummer nennen kannst, bei der du
feststeckst.

---

## 1. „Internet geht nicht / Seiten laden nicht"

Der häufigste Fall — meist ist es gar kein Internetproblem.

**Ist Tailscale an?** (Mac: Symbol in der Menüleiste. iPhone: VPN-Symbol
in der Statuszeile.) Falls nicht: App öffnen, verbinden. Mehr dazu in
`handbuch/tailscale.md`.

Wenn „Verbinden" nicht reicht und die App nach einem Login fragt: das
ist normal — mit deinem Tailscale-Account anmelden, dann verbindet sie
sich wieder.

Tailscale ist an, aber es geht trotzdem nicht? → weiter zu Schritt 2
(Werbung) bzw. Schritt 3 (Bitwarden) — oder Markus anrufen: „Schritt 1
hat nicht geholfen".

---

## 2. „Werbung ist plötzlich wieder da"

1. Wie Schritt 1: Ist Tailscale an?
2. Falls Tailscale läuft: Pi-hole-Dashboard am Mac aufrufen —
   `http://<Tailscale-IP>:8080/admin`. Lädt die Seite? Falls nicht,
   weiter mit Schritt 3/4 (Container prüfen).
3. Lädt das Dashboard, aber die Werbung bleibt trotzdem? → Markus
   anrufen: „Schritt 2, Dashboard erreichbar".

---

## 3. „Bitwarden synct nicht"

1. Wie Schritt 1: Ist Tailscale an?
2. Falls Tailscale läuft: am Mac verbinden und Container prüfen:

```bash
ssh vps
docker ps
```

Läuft `vaultwarden` und steht bei STATUS `Up ...`? Falls nicht, weiter
mit Schritt 4.

Läuft der Container trotzdem (`Up ...`), synct aber immer noch nicht?
In der Bitwarden-App die Server-URL prüfen — steht dort genau
`https://<maschinenname>.<tailnet>.ts.net`? Falls das stimmt und es
trotzdem nicht geht: Markus anrufen: „Schritt 3, Container läuft".

---

## 4. Ein Container steht

Neu starten:

```bash
cd /srv/docker/<dienst> && docker compose restart
```

(`<dienst>` ist `pihole` oder `vaultwarden`, je nachdem, was betroffen
ist.)

Logs ansehen, falls der Neustart nicht hilft:

```bash
docker logs <dienst> --tail 50
```

Mehr zu Docker-Befehlen: `handbuch/docker-basics.md`.

---

## 5. Der Server ist komplett weg

Wenn selbst `ssh vps` gar nicht mehr reagiert: Webkonsole beim Hoster
öffnen (Notfall-Zugang, funktioniert auch ohne SSH und ohne Tailscale).
Dort:

```bash
sudo reboot
```

Danach ein paar Minuten warten und erneut mit `ssh vps` verbinden.

---

## 6. „Läuft das Backup noch?"

```bash
systemctl list-timers christina-backup.timer
ls -lh /srv/backups
tail /var/log/christina-backup.log
```

`list-timers` zeigt, wann der nächste Lauf ansteht. In `/srv/backups`
sollten frische Dateien liegen. Im Log sollte keine Zeile mit FEHLER
oder WARNUNG stehen.

Steht dort FEHLER oder WARNUNG? Nichts selbst reparieren — Markus
Bescheid geben: „Schritt 6, Log zeigt Fehler".

---

## 7. Goldene Regeln

- **Nichts löschen, was du nicht kennst.** Wenn du unsicher bist, ob
  eine Datei oder ein Ordner wichtig ist — lieber liegen lassen.
- **Bei Unsicherheit: Markus anrufen.** Nenn ihm einfach die Nummer aus
  dieser Liste, bei der du feststeckst (z. B. „ich bin bei Punkt 4") —
  das reicht ihm, um sofort zu wissen, wo du stehst.
