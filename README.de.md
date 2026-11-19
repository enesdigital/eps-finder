# EPS Finder

[English](README.md) · [Türkçe](README.tr.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md)

EPS-Miniaturansichten und Vorschauen mit der Leertaste über Quick Look im macOS-Finder.

**Universal 2:** Intel (`x86_64`) und Apple Silicon (`arm64`). **macOS 13 oder neuer.** Ghostscript ist enthalten. Für die Nutzung sind weder Homebrew noch Python, Illustrator oder Rosetta erforderlich.

Die Benutzeroberfläche, Fehlermeldungen und Installationsseiten sind auf Türkisch, Englisch, Deutsch, Französisch und Spanisch verfügbar. macOS wählt automatisch die passende Sprache aus deinen Spracheinstellungen. Wenn keine unterstützte Sprache verfügbar ist, wird Englisch verwendet.

## Installation

1. Lade `EPS-Finder-1.3.0-universal-unsigned.pkg` unter [Releases](https://github.com/enesdigital/eps-finder/releases/latest) herunter. Dasselbe Paket unterstützt Intel und Apple Silicon.
2. Öffne die `.pkg`-Datei und folge dem Installationsassistenten. Die App wird unter `/Applications/EPS Finder.app` installiert; eine Administratorfreigabe ist erforderlich.
3. Öffne EPS Finder einmal. Über **Beispieldatei anzeigen** wird die mitgelieferte EPS-Beispieldatei im Finder ausgewählt.

Das Installationsprogramm registriert die Quick-Look-Erweiterungen für den angemeldeten Benutzer. Andere Benutzerkonten müssen die App gegebenenfalls ebenfalls einmal öffnen.

Diese Version besitzt **keine Developer-ID-Signatur und wurde nicht von Apple notarisiert**. macOS kann eine Bestätigung verlangen, bevor das Paket geöffnet wird. Signierung und Notarisierung sind ein separater Schritt für die Verteilung.

## Verwendung

Wähle im Finder eine `.eps`-Datei aus und drücke die **Leertaste**, um die Vorschau zu öffnen. In der Symbolansicht erstellt der Finder auch Miniaturansichten. Aktiviere dafür die Symbolvorschau in den Darstellungsoptionen des Finders.

## Updates

EPS Finder sucht bei jedem Öffnen auf GitHub nach einer neueren stabilen Version. Du kannst **Beim Öffnen von EPS Finder automatisch nach Updates suchen** deaktivieren oder **Nach Updates suchen** verwenden.

Wähle bei einer neuen Version **Laden und installieren…**. Die App lädt das universelle Paket aus diesem Repository, prüft Dateigröße und den von GitHub bereitgestellten SHA-256-Wert und öffnet das macOS-Installationsprogramm. EPS Finder wird beim Öffnen des Installationsprogramms beendet, damit der alte Prozess nicht weiterläuft. Schließe die Installation mit Administratorfreigabe ab und öffne EPS Finder erneut. **Versionshinweise** öffnet die Seite für den manuellen Download.

Version 1.2.0 und älter haben keinen Updater. Installiere zunächst einmal Version 1.3.0 über Releases. Nach der Installation registriert sich EPS Finder als macOS-Anmeldeobjekt und sucht bei jeder Anmeldung nach Updates. Du kannst **EPS Finder bei der Anmeldung starten** deaktivieren oder die Systemeinstellungen → Allgemein → Anmeldeobjekte verwenden. Eine dort deaktivierte Einstellung wird respektiert. Es wird kein zusätzlicher Hintergrunddienst installiert. Nur die App verbindet sich mit GitHub und dessen Download-Servern. EPS-Dateien werden nicht hochgeladen; die Quick-Look-Erweiterungen erhalten keinen Netzwerkzugriff.

Das Paket bleibt unsigniert und nicht notarisiert. SHA-256 prüft die Integrität des Downloads und ersetzt weder eine Developer-ID-Signatur noch eine macOS-Sicherheitsfreigabe. Unvollständige oder fehlerhafte Downloads werden gelöscht. Bei Netzwerkfehlern oder einem GitHub-Anfragelimit kannst du es später erneut versuchen.

Bei manuellen Installationen und App-Updates wird `/Applications/EPS Finder.app` ersetzt. Ältere Kopien mit derselben Bundle-ID in `/Applications` und `~/Applications` des angemeldeten Benutzers werden in den Papierkorb verschoben. Andere Benutzer werden beim nächsten Öffnen der neuen App geprüft. Gleich neue oder neuere Versionen, andere Apps, symbolische Links und EPS-Dokumente bleiben erhalten. Andere Ordner werden nicht durchsucht. Falls eine Kopie nicht verschoben werden kann, weist die App auf die manuelle Bereinigung hin.

## Wenn keine Vorschau erscheint

1. Prüfe, ob die Datei vollständig auf den Mac heruntergeladen wurde und nicht nur als Cloud-Platzhalter vorliegt.
2. Öffne EPS Finder einmal. Suche in den Systemeinstellungen nach **Erweiterungen / Übersicht (Quick Look)** und aktiviere **EPS Finder — Vorschau** und **EPS Finder — Miniaturansichten**. Der genaue Ort der Einstellung hängt von der macOS-Version ab.
3. Prüfe die Symbolvorschau im Finder. Beschädigte EPS-Dateien oder Dateien mit fehlenden externen Ressourcen lassen sich möglicherweise nicht anzeigen.

## Verarbeitung und Grenzen

Die Quick-Look-Erweiterung wandelt EPS in ihrer Sandbox mit Ghostscript im `SAFER`-Modus in eine temporäre PDF um. Die Verarbeitung erfolgt lokal. Die ursprüngliche EPS-Datei wird nicht verändert; temporäre Dateien werden entfernt. Die Quick-Look-Erweiterungen erhalten weder Netzwerkzugriff noch weitreichende Dateizugriffsrechte. Die Haupt-App nutzt das Netzwerk nur für Update-Prüfungen und Downloads.

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

Die Skripte prüfen den SHA-256-Wert des offiziellen Ghostscript-Archivs, erstellen beide Architekturen, führen die Renderer-Tests aus und schreiben Installationspaket, vollständiges Quellarchiv und Prüfsummen nach `dist/`. Weitere Einzelheiten stehen in der [englischen Anleitung](README.md#build).

Die Tests für arm64 und x86_64 wurden erfolgreich ausgeführt; der Intel-Code lief über Rosetta auf Apple Silicon. Tests auf einem physischen Intel-Mac, unter der ältesten unterstützten macOS-Version und eine vollständige Installation mit Administratorfreigabe stehen noch aus.

## Lizenz und Downloads

AGPL-3.0-or-later; siehe [LICENSE](LICENSE) und [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Gib das erzeugte Quellarchiv zusammen mit dem Binärpaket weiter.

Unter [Releases](https://github.com/enesdigital/eps-finder/releases/latest) stehen Installationspaket, `EPS-Finder-1.3.0-source.zip` und die Datei `SHA256SUMS` bereit. Das ausdrücklich benannte Quellarchiv enthält auch die vollständigen Ghostscript-Quellen. Die von GitHub automatisch erzeugten „Source code“-Archive enthalten dieses zusätzliche Archiv nicht.
