# EPS Finder

[Türkçe](README.md) · [English](README.en.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md)

EPS-Miniaturansichten und Vorschauen mit der Leertaste über Quick Look im macOS-Finder.

**Universal 2:** Intel (`x86_64`) und Apple Silicon (`arm64`). **macOS 13 oder neuer.** Ghostscript ist enthalten. Für die Nutzung sind weder Homebrew noch Python, Illustrator oder Rosetta erforderlich.

## Installation

1. Lade `EPS-Finder-1.1.0-universal-unsigned.pkg` unter [Releases](https://github.com/enesdigital/eps-finder/releases/latest) herunter. Dasselbe Paket unterstützt Intel und Apple Silicon.
2. Öffne die `.pkg`-Datei und folge dem Installationsassistenten. Die App wird unter `/Applications/EPS Finder.app` installiert; eine Administratorfreigabe ist erforderlich.
3. Öffne EPS Finder einmal. Über **Örnek dosyayı göster** („Beispieldatei anzeigen“) wird die mitgelieferte EPS-Beispieldatei im Finder ausgewählt. Der Dialog der App ist derzeit auf Türkisch.

Das Installationsprogramm registriert die Quick-Look-Erweiterungen für den angemeldeten Benutzer. Andere Benutzerkonten müssen die App gegebenenfalls ebenfalls einmal öffnen.

Diese Version besitzt **keine Developer-ID-Signatur und wurde nicht von Apple notarisiert**. macOS kann eine Bestätigung verlangen, bevor das Paket geöffnet wird. Signierung und Notarisierung sind ein separater Schritt für die Verteilung.

## Verwendung

Wähle im Finder eine `.eps`-Datei aus und drücke die **Leertaste**, um die Vorschau zu öffnen. In der Symbolansicht erstellt der Finder auch Miniaturansichten. Aktiviere dafür die Symbolvorschau in den Darstellungsoptionen des Finders.

## Wenn keine Vorschau erscheint

1. Prüfe, ob die Datei vollständig auf den Mac heruntergeladen wurde und nicht nur als Cloud-Platzhalter vorliegt.
2. Öffne EPS Finder einmal. Suche in den Systemeinstellungen nach **Erweiterungen / Übersicht (Quick Look)** und aktiviere **EPS Finder — Preview** und **EPS Finder — Thumbnail**. Der genaue Ort der Einstellung hängt von der macOS-Version ab.
3. Prüfe die Symbolvorschau im Finder. Beschädigte EPS-Dateien oder Dateien mit fehlenden externen Ressourcen lassen sich möglicherweise nicht anzeigen.

## Verarbeitung und Grenzen

Die Quick-Look-Erweiterung wandelt EPS in ihrer Sandbox mit Ghostscript im `SAFER`-Modus in eine temporäre PDF um. Die Verarbeitung erfolgt lokal. Die ursprüngliche EPS-Datei wird nicht verändert; temporäre Dateien werden entfernt. Die App fordert weder Netzwerkzugriff noch weitreichende Dateizugriffsrechte an.

- Maximale Eingabegröße: 256 MB. Maximale erzeugte PDF: 64 MB.
- Zeitlimit: 8 Sekunden für Miniaturansichten, 15 Sekunden für Vorschauen.
- Nicht eingebettete Schriftarten können anders aussehen; externe Ressourcen können die Anzeige verhindern.
- Die Vorschau ersetzt keine Druck- oder Farbfreigabe.

Zum Deinstallieren verschiebe `/Applications/EPS Finder.app` in den Papierkorb. Entferne gegebenenfalls auch eine ältere Kopie im Programme-Ordner deines Benutzerkontos.

## Kompilieren und Tests

Für die Universal-Version werden ein **Apple-Silicon-Mac, Rosetta 2, Apple Command Line Tools und Python 3.9+** benötigt. Diese Anforderungen gelten nur für die Entwicklung.

```sh
python3 build-engine.py
python3 build.py
python3 package.py
```

Die Skripte prüfen den SHA-256-Wert des offiziellen Ghostscript-Archivs, erstellen beide Architekturen, führen die Renderer-Tests aus und schreiben Installationspaket, vollständiges Quellarchiv und Prüfsummen nach `dist/`. Weitere Einzelheiten stehen in der [englischen Anleitung](README.en.md#build).

Die Tests für arm64 und x86_64 wurden erfolgreich ausgeführt; der Intel-Code lief über Rosetta auf Apple Silicon. Tests auf einem physischen Intel-Mac, unter der ältesten unterstützten macOS-Version und eine vollständige Installation mit Administratorfreigabe stehen noch aus.

## Lizenz und Downloads

AGPL-3.0-or-later; siehe [LICENSE](LICENSE) und [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Gib das erzeugte Quellarchiv zusammen mit dem Binärpaket weiter.

Unter [Releases](https://github.com/enesdigital/eps-finder/releases/latest) stehen Installationspaket, `EPS-Finder-1.1.0-source.zip` und die Datei `SHA256SUMS` bereit. Das ausdrücklich benannte Quellarchiv enthält auch die vollständigen Ghostscript-Quellen. Die von GitHub automatisch erzeugten „Source code“-Archive enthalten dieses zusätzliche Archiv nicht.
