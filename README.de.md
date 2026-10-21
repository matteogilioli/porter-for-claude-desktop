<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.it.md">Italiano</a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.fr.md">Français</a> ·
  <b>Deutsch</b> ·
  <a href="README.pt-BR.md">Português</a> ·
  <a href="README.zh-Hans.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.ru.md">Русский</a>
</p>

<p align="center">
  <img src="assets/readme/hero.svg" width="100%" alt="Porter trägt Claude-Code-Sitzungen von einem Konto am Nutzungslimit zu einem Konto mit freiem Kontingent">
</p>

<p align="center">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-2B2522?logo=apple&logoColor=white">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-5.9-C96442?logo=swift&logoColor=white">
  <img alt="10 Sprachen" src="https://img.shields.io/badge/languages-10-433053">
  <a href="LICENSE"><img alt="MIT-Lizenz" src="https://img.shields.io/badge/license-MIT-4F8A5B"></a>
  <a href="https://github.com/sponsors/matteogilioli"><img alt="Sponsor" src="https://img.shields.io/badge/sponsor-♥-E8906A"></a>
</p>

**Porter** ist eine kleine macOS-Menüleisten-App für den **Code**-Tab von Claude Desktop. Erreicht ein Konto sein Nutzungslimit, überträgt Porter deine Claude-Code-Sitzungen auf ein anderes Konto, sodass du dieselben Unterhaltungen genau dort fortsetzt, wo sie stehen geblieben sind. Außerdem kannst du **mehrere Claude Desktops nebeneinander** betreiben, je einen pro Konto, und deine Sitzungen aufgeräumt halten: archivieren, wiederherstellen, löschen und ganze Projekte verschieben.

> [!NOTE]
> Inoffiziell und nicht mit Anthropic verbunden. Porter liest und schreibt die eigenen Dateien von Claude Desktop, die nicht dokumentiert sind und sich mit jedem Update ändern können. Vor jeder Änderung legt Porter ein Backup an.

## Mehrere Claude Desktops gleichzeitig

<p align="center">
  <img src="assets/readme/profiles.svg" width="100%" alt="Drei gleichzeitig geöffnete Claude-Desktop-Fenster, jedes mit einem anderen Konto angemeldet, alle im Porter-Fenster aufgelistet">
</p>

Claude Desktop läuft normalerweise mit einem Konto zugleich: Für ein anderes meldest du dich ab und wieder an. Mit Porter ist das nicht nötig.

- **Neues Profil…** öffnet ein eigenes Claude Desktop mit separater Anmeldung, eigenen Einstellungen und eigener Sitzungsliste. Melde dich dort mit einem anderen Konto an und lass beide Fenster offen.
- Lege so viele Profile an, wie du Konten hast (Arbeit, privat, ein Kunde …). Alle laufen **gleichzeitig**, im Dock und mit ⌘-Tab wie jede andere App.
- Porter listet jedes Profil mit Konto, zuletzt erfasster Nutzung und den durch ein Limit gestoppten Sitzungen auf. Du kannst es öffnen oder in den Vordergrund holen, umbenennen oder entfernen.
- Sitzungen zwischen Profilen zu verschieben ist ein Klick, und wenn ein Konto ausgeschöpft ist, arbeitest du einfach im nächsten Fenster weiter.
- **Links im richtigen Profil öffnen** (in den Optionen): Alle Profile sind dieselbe Claude-App, daher kann dich macOS nach der Anmeldung im Browser zu einem beliebigen offenen Profil zurückschicken. Mit dieser Option gibt Porter Claude-Links an das zuletzt verwendete Profil weiter.

Lieber ein einziges Claude Desktop und die Konten per Ab- und Anmelden wechseln? Schalte **Mehrere Profile** in den Optionen aus: Porter listet dann Konten statt Apps auf und verschiebt die Sitzungen des alten Kontos auf das Konto, bei dem du gerade angemeldet bist.

## Das Menüleisten-Fenster

<img src="assets/readme/panel.svg" width="44%" align="right" alt="Das Menüleisten-Fenster von Porter: Konto-Karten mit Nutzungsbalken für 5 Stunden und 7 Tage, ein Hinweis auf durch das Limit gestoppte Sitzungen und eine Schaltfläche zum Verschieben">

Klick in der Menüleiste auf den Gepäckträger, um alle Konten auf einen Blick zu sehen:

- **Nutzung der letzten 5 Stunden und 7 Tage** für jedes Konto: grün, solange noch Luft ist, orange nahe am Limit, rot, wenn es erreicht ist. Ein Wert, den Claude Desktop vor einer Weile gespeichert hat, wird ausgeblendet mit seinem Alter angezeigt, und ein 5-Stunden-Fenster, das sicher schon zurückgesetzt wurde, wird als solches gekennzeichnet.
- **Durch das Limit gestoppte Sitzungen**, pro Konto gezählt und mit einem Punkt am Menüleistensymbol.
- **6 nach Personal verschieben →**: Ein Klick verschiebt die gestoppten Sitzungen auf das Konto mit dem meisten freien Kontingent.
- **Sitzungen ›** öffnet dieses Konto im Hauptfenster.

<br clear="right">

## Das Hauptfenster

<p align="center">
  <img src="assets/readme/window.svg" width="100%" alt="Das Hauptfenster von Porter: Konten in einer Seitenleiste, nach Projekt gruppierte Sitzungen, drei ausgewählte Sitzungen und eine Aktionsleiste mit Archivieren, Löschen und Verschieben nach">
</p>

Alle Konten und ihre Claude-Code-Sitzungen an einem Ort:

- **Nach Projekt gruppierte Sitzungen**, mit Filtern (offen, durch das Limit gestoppt, archiviert), Projektmenü und Suche. Ein grünes Abzeichen markiert gerade aktive Sitzungen, damit du keine mitten in einer Antwort verschiebst.
- **Auswählen** per Klick, ⇧-Klick für einen Bereich oder *Alle auswählen*. Unten erscheint die Aktionsleiste:
  - **Verschieben nach…**: Wähle das Zielkonto. Die Originale werden archiviert, damit dieselbe Sitzung nicht an zwei Orten fortgesetzt wird.
  - **Kopieren**: Die Sitzungen bleiben in beiden Konten, und jede Kopie bekommt eine eigene Unterhaltung.
  - **Archivieren**, **Wiederherstellen** und **Löschen…** (in den Papierkorb, du kannst sie also zurückholen).
- **Ziehe** Sitzungen auf ein anderes Konto in der Seitenleiste, um sie dorthin zu verschieben.
- **Projektordner verschieben** (oder neu verknüpfen, nachdem du ihn im Finder verschoben hast): Porter aktualisiert jede Sitzung, die ihn verwendet, in jedem Konto, samt Unterhaltungen und Git-Worktrees. Projekte, deren Ordner fehlt, sind mit *Ordner fehlt* markiert.

## So funktioniert es

<p align="center">
  <img src="assets/readme/how-it-works.svg" width="100%" alt="Diagramm: Porter kopiert eine kleine Sitzungsdatei aus der Sitzungsliste eines Kontos in die eines anderen; die Unterhaltung bleibt in ~/.claude/projects und wird von allen Konten gemeinsam genutzt; Chats bleiben auf den Servern von Anthropic">
</p>

Eine Claude-Code-Unterhaltung liegt im eigenen Ordner von Claude Code, `~/.claude/projects`, der zu keinem Konto gehört. Zu einem Konto gehört nur die **Liste** der Sitzungen von Claude Desktop:

```
<data folder>/claude-code-sessions/<account>/<organization>/local_<session>.json
```

(der Standard-Datenordner ist `~/Library/Application Support/Claude`). Beim Verschieben einer Sitzung wird diese kleine Datei in die Liste des anderen Kontos kopiert, der Fehler „You've hit your limit“ entfernt und die verwendeten Git-Worktrees werden mitgenommen. Ein laufendes Claude Desktop hält seine Liste im Speicher, deshalb beendet Porter es zuerst und öffnet es danach wieder.

> [!IMPORTANT]
> Porter arbeitet mit dem, was Claude Desktop **auf deinem Mac** speichert: Sitzungen des **Code**-Tabs. Chats, auch solche, in denen Claude an deinen Dateien arbeitet, liegen auf den Servern von Anthropic und bleiben bei ihrem Konto.

## Installation

Voraussetzung sind **macOS 14** oder neuer und [Claude Desktop](https://claude.ai/download).

**Download:** Lade `Porter.dmg` aus dem [neuesten Release](../../releases/latest) herunter, öffne es und ziehe **Porter for Claude Desktop** in den Ordner `Applications`. Die App ist nicht notarisiert, deshalb blockiert macOS sie beim ersten Mal: Öffne **Systemeinstellungen → Datenschutz & Sicherheit** und klicke auf **Dennoch öffnen**, oder führe aus:

```bash
xattr -dr com.apple.quarantine "/Applications/Porter for Claude Desktop.app"
```

**Aus dem Quellcode bauen** (Xcode oder die Command Line Tools):

```bash
git clone https://github.com/matteogilioli/porter-for-claude-desktop.git
cd porter-for-claude-desktop
./scripts/build-app.sh --install
```

Das erzeugt `dist/Porter for Claude Desktop.app` und kopiert die App nach `~/Applications`. Aktiviere **Bei Anmeldung öffnen** in den Optionen, damit Porter immer zur Hand ist.

Porter spricht English, Italiano, Español, Français, Deutsch, Português, 简体中文, 日本語, 한국어 und Русский und folgt der Sprache deines Macs.

## Kommandozeile

Dieselbe App verschiebt Sitzungen auch aus Skripten:

```bash
PORTER="/Applications/Porter for Claude Desktop.app/Contents/MacOS/Porter"
"$PORTER" --list                                        # Konten, Profile und ihre Sitzungslisten
"$PORTER" --move --from STORE --to STORE --dry-run      # was passieren würde
"$PORTER" --move --from STORE --to STORE --restart      # verschieben (Originale archiviert)
"$PORTER" --move --from STORE --to STORE --copy         # stattdessen kopieren
```

`STORE` ist ein Pfad, den `--list` ausgibt. Mit `--session local_…` (wiederholbar) wählst du einzelne Sitzungen, mit `--include-archived` nimmst du auch archivierte mit, und mit `--data-dir PATH` gibst du einen Claude-Datenordner an, den Porter noch nicht kennt.

Porter beendet ein laufendes Claude Desktop nur mit `--restart` (und öffnet es danach wieder; das Ziel wird neu gestartet oder geöffnet, damit es die Sitzungen lädt). Ohne die Option bricht ein Verschieben, das eine App beenden müsste, ab und nennt sie. `--dry-run` zeigt, welche Apps beendet würden.

## Gut zu wissen

- **Rückgängig machen:** Jede Änderung beginnt mit einem Backup in `~/Library/Application Support/Porter/backups`. Um ein Verschieben rückgängig zu machen, beende Claude Desktop und kopiere die gesicherten Dateien in den Pfad zurück, der in der `README.txt` des Backups steht.
- **Nutzungszahlen** stammen aus dem, was Claude Desktop aufzeichnet, und zwar hin und wieder, während du ein Konto verwendest. Porter zeigt, wie alt ein Wert ist. Mit **Live-Nutzung** (in den Optionen) fragt Porter stattdessen alle paar Minuten claude.ai, mit der Sitzung jedes Profils, und zeigt auch, wann jedes Limit zurückgesetzt wird, sowie Limits für ein einzelnes Modell wie Fable. macOS fragt einmal, ob Porter den Schlüssel verwenden darf, den Claude im Schlüsselbund aufbewahrt.
- **Immer nur an einem Ort:** Arbeite nicht gleichzeitig von zwei Konten aus an derselben Sitzung weiter. Deshalb archiviert das Verschieben das Original; nutze Kopieren, wenn du wirklich zwei unabhängige Sitzungen willst.
- Verwende nur Konten, die dir gehören, und halte die Bedingungen deines Claude-Tarifs ein.

## Unterstützung

Porter ist kostenlos und Open Source. Wenn es dir Wartezeit erspart, kannst du es [auf GitHub unterstützen](https://github.com/sponsors/matteogilioli).

## Lizenz

[MIT](LICENSE). Claude ist eine Marke von Anthropic, PBC. Porter ist ein unabhängiges Projekt und steht in keiner Verbindung zu Anthropic und wird auch nicht von Anthropic unterstützt.
