# Serpent

[🇺🇸 English](README.md) · [🇨🇳 简体中文](README.zh-Hans.md) · [🇹🇼 繁體中文](README.zh-Hant.md) · [🇯🇵 日本語](README.ja.md) · [🇰🇷 한국어](README.ko.md) · [🇫🇷 Français](README.fr.md) · [🇩🇪 Deutsch](README.de.md) · [🇪🇸 Español](README.es.md)

Ein natives, minimalistisches Snake-Spiel für Macs mit Apple Silicon, entwickelt mit SwiftUI, AppKit und AVFoundation. Keine Laufzeitabhängigkeiten von Drittanbietern und keine Netzwerkanfragen.

## Erste Schritte

Öffne `dist/Serpent.app` oder entpacke `dist/Serpent-Apple-Silicon.zip`. Du kannst die App in deinen Programme-Ordner ziehen. Erforderlich ist ein Mac mit Chip der M-Serie und macOS 13 Ventura oder neuer.

Die lokal erstellte Version ist ad hoc signiert und wurde nicht mit einer Apple Developer ID notarisiert. Falls macOS die App nach dem Herunterladen auf einem anderen Mac blockiert, folge den Systemhinweisen, um das Öffnen zu erlauben.

## Steuerung

| Aktion | Steuerung |
| --- | --- |
| Bewegen | Pfeiltasten, WASD oder Ziehen/Wischen auf dem Spielfeld |
| Starten, pausieren oder fortsetzen | Leertaste |
| Neues Spiel | R oder ⌘N |
| Pausieren oder Einstellungen/Hilfe schließen | Esc |
| Einstellungen | ⌘, |

Sammle Futter, damit deine Schlange wächst. Ein Zusammenstoß mit einer Wand beendet die Runde, sofern „Ränder durchqueren“ deaktiviert ist. Ein Zusammenstoß mit deinem eigenen Körper beendet die Runde immer. Direkte Kehrtwenden um 180° werden ignoriert. Schnell eingegebene gültige Richtungswechsel werden in eine Warteschlange aufgenommen und bei aufeinanderfolgenden Bewegungsschritten ausgeführt.

Das Spiel pausiert automatisch, wenn du zu einer anderen App wechselst, das Fenster minimierst oder deinen Mac in den Ruhezustand versetzt. Drücke nach deiner Rückkehr die Leertaste, um weiterzuspielen.

## Funktionen

- Natives Desktopfenster mit Größenanpassung, Vollbildunterstützung und Retina-/hochauflösender Darstellung.
- Helles, dunkles oder systemabhängiges Erscheinungsbild. Standardmäßig folgt die App dem Erscheinungsbild deines Mac.
- Flüssige Darstellung mit 60 Hz, sanft pulsierendes Futter und animierte Aktualisierungen des Punktestands.
- Drei Schwierigkeitsstufen mit jeweils eigenem Bestwert:

  | Schwierigkeit | Zeit pro Bewegung | Punkte pro Futter |
  | --- | --- | --- |
  | Leicht | 160 ms | 10 |
  | Normal | 105 ms | 20 |
  | Schwer | 70 ms | 30 |

  Änderungen der Schwierigkeit gelten ab dem nächsten Spiel.

- Der unabhängige Schalter **Ränder durchqueren** befindet sich unter **Einstellungen → Spiel** und ist standardmäßig aus. Wenn er aktiviert ist, erscheint die Schlange nach dem Überschreiten eines Randes am gegenüberliegenden Rand. Änderungen gelten ab dem nächsten Spiel; ein Zusammenstoß mit dem eigenen Körper beendet die Runde weiterhin. Bestwerte werden für jede Schwierigkeit und jeden Modus getrennt gespeichert. Vorhandene Rekorde des klassischen Modus bleiben erhalten.

- Optionale, sanfte synthetische Klänge beim Starten, Sammeln von Futter, Pausieren, Beenden einer Runde und Aufstellen eines neuen Rekords.
- Bestwerte, Einstellungen und Sprachauswahl werden lokal gespeichert.
- Acht vollständig übersetzte Sprachen, die in den Einstellungen über Flaggen ausgewählt werden können:

  | Sprache | Region |
  | --- | --- |
  | 🇺🇸 Englisch | Vereinigte Staaten |
  | 🇨🇳 Vereinfachtes Chinesisch | China |
  | 🇹🇼 Traditionelles Chinesisch | Taiwan |
  | 🇯🇵 Japanisch | Japan |
  | 🇰🇷 Koreanisch | Südkorea |
  | 🇫🇷 Französisch | Frankreich |
  | 🇩🇪 Deutsch | Deutschland |
  | 🇪🇸 Spanisch | Spanien |

  Die Standardsprache richtet sich nach den bevorzugten Sprachen deines Mac. Du kannst sie jederzeit in den Einstellungen ändern.

## Entwicklung und Paketierung

Erforderlich sind die Xcode Command Line Tools und Swift 5.9 oder neuer.

```sh
swift test
swift run Serpent
./Scripts/build-app.sh
```

Das Paketierungsskript erstellt eine arm64-App und ein ZIP-Archiv und überprüft anschließend die Signatur der App. Führe `BUILD_DMG=1 ./Scripts/build-app.sh` aus, um zusätzlich ein Disk-Image zu erstellen.

Automatisierte Tests prüfen die Spielregeln, die Warteschlange für Richtungswechsel, Grenzfälle, das automatische Pausieren, die Zuordnung der Systemsprache und die Vollständigkeit der Übersetzungen in allen acht Sprachen.

Die Quelldateien liegen in `Sources/Serpent`, die Übersetzungen in `Sources/Serpent/Resources` und das App-Symbol sowie die Metadaten in `Support`.
