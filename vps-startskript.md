---
title: vps-startskript
date: 2026-07-19
tags: []
source: []
links: []
---

# Ziel

Auf einem Debian VPS, 1CPU 1GB, soll folgendes installiert werden.

- zsh und oh-my-zsh
- docker
- pihole mit unbound (docker)
- vaultwarden (docker)
- fail2ban
- tailscale
- 2 user mit home verzeichniss
- firewall
- backups lokal um später mit sycthing mit einer nas zu verbinden

# PiHole und Vaultwarden

beide sollen mit docker compose und persistente daten und unterverzeichnissen
laufen um backupos sicher zu machen. pihole und dns sollen nur über tailscale
nutzbar sein. Nicht öffentlich machen da ein VPS mit öffentlicher IP.

# Tailscale

Wird der kostenlose Account von tailscale genommen und dort wird der Pihole als
DNS eingetragen. auch ssh auf das VPS soll später nur über tailscale laufen.

# VPS

alle ports nach aussen dicht machen, nur ssh bis alles eingerichtet ist. ssh
dann per pubkey, root login disabled und poassowrt login ebenfalls disabled.
Firewall soll für tailscale netze offen sein.

# Docker

den daemon absichern, docker härten wo es geht.

# Anmerkung

Dieses Sertup ist für eine Freundin die ihre Daten souverän verarbeiten möchte.
Deshalb pihole und ein eigener Passworsafe. Jedoch hat sie keine Ahnung von
Linux, von Docker und von der CL. Ich würde als admin fungieren, möchte aber das
sie selbständig wird im Umgang mit Linux, CL, Docker und einem Debian 13 VPS.
Alles gaaaaaaaanz gemächlich. Ich bin da. Was ich vermeiden möchte ist ein
schwarzes Loch das ich ihr installiere und sie keine Ahnung hat was da abgeht,
wie man nachschauen kann wenn was klemmt, nicht funkt usw. Und wie sie
vielleicht selbst updates machen kann. Also wir benötigen auch eine Neuling
Doku. Jedoch möchte ich es ihr an einem Nachmittag einrichten und dann erstmal
als Admin fungieren. Wir müssen dann noch tailscale registrieren und auch dort
muss ich ihr die funktionsweise und handling erklären. Auch dafür eine einfache
Doku. Das ganz soll einfach sein. Ein skript das Debian sicher, updated und alle
benötigeten requirements instlliert für den Betrieb, ebenfalls die firewall
aktiviert und in der doku die näschsten schritte aufzeigt wie "tailscale ist
verbunden, jetzt nehmen wir das in die firewall auf und blockieren den port über
alle anderen interfaces" sowas. Ich möchte nicht das das skript alles machjt.
sie soll verstehen was da gemahct wird, warum usw.
