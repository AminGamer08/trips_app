# Adventure Journal

**Deine Welt. Deine Geschichten.** Eine funktionierende Flutter-App für Orte,
Reisen, Fotos und persönliche Erinnerungen. Deutschsprachig, mit Material You,
lokaler Datenbank und einer vollständig mitgelieferten geografischen Karte.

## Starten

Entwickelt mit Flutter **3.38.5** / Dart **3.10.4**. Abhängigkeiten sind im
Lockfile festgehalten. Android SDK 36 und JDK 17 oder 21 werden benötigt.

```sh
flutter pub get
flutter run
```

Android-Emulator starten oder Smartphone verbinden. Kein API-Key, Account oder
Backend nötig. Beim ersten Start entstehen 14 Beispielorte in fünf Reisen
(Paris, Amsterdam, Barcelona, Rom und Berlin), verteilt auf alle sechs Kategorien.
Die Fotos und die Schrift sind gebündelt; es gibt keine Netzwerk-Bildanfragen.

```sh
flutter build apk --debug
flutter test
flutter analyze
flutter test integration_test/app_flow_test.dart -d emulator-5554
```

Die Test-APK liegt unter `build/app/outputs/flutter-apk/app-debug.apk`.
Für eine Veröffentlichung eine eigene Android-Signatur konfigurieren;
die mitgelieferte Release-Konfiguration verwendet den Flutter-Debug-Schlüssel.

### Browser-Vorschau

```sh
flutter config --enable-web
flutter run -d chrome
flutter build web --release --no-web-resources-cdn
```

Der Web-Build enthält CanvasKit lokal. Browserdaten liegen in IndexedDB und
sind an die jeweilige Herkunft/Portnummer gebunden. Standortfreigabe benötigt
localhost oder HTTPS. Die mobile App speichert unabhängig im privaten
App-Verzeichnis und funktioniert bereits beim ersten Start ohne Internet.

### iOS

Auf einem Mac mit Xcode und CocoaPods `flutter pub get` und anschließend
`flutter run` ausführen. Deployment Target ist iOS 13. Die Beschreibungen für
Standort-, Galerie- und Kamerafreigaben und der Podfile sind enthalten.
In Xcode unter Runner → Signing das eigene Team auswählen. iOS-Builds können
auf dieser Windows-Umgebung nicht ausgeführt werden.

## Enthalten

- Dashboard mit letzter/aktueller Reise, Zählwerten, neuen Orten und Kartenübersicht.
- Orte anlegen, bearbeiten und löschen; Eingabeprüfung und Schutz vor versehentlichem
  Verlassen ungespeicherter Formulare. Datum und Uhrzeit, Kategorie, 1–5 Sterne,
  Koordinaten, Beschreibung, Notizen, Fotos und optionale Reisezuordnung.
- Interaktive Offline-Karte: verschieben, zoomen, Pins, Cluster, Vorschaukarten,
  Kategorien, Standort und Koordinatenauswahl. Marker mit gleichen Koordinaten
  bleiben über eine Auswahl erreichbar.
- Reisen erstellen, bearbeiten und löschen, eigene Cover, Zeiträume, Karten,
  chronologische Timeline und berechnete Kennzahlen. Reise-Löschen behält Orte.
- Globale Suche nach Name, Stadt, Land und Beschreibung. Kombinierbare Kategorie-,
  Land-, Mindestbewertungs- und Zeitraumfilter im Bottom Sheet.
- Statistik mit Kategorie-Ringdiagramm, Reisen pro Jahr, häufigsten Ländern,
  Städten, Orten, Fotos, Bewertungsdurchschnitt und Luftlinien-Distanzen.
- Galerie- und Kameraauswahl auf Android/iOS, persistente Fotokopien in einem
  separaten Datenbank-Store, horizontale Galerie und Vollbildansicht mit Zoom.
  Fehlende oder defekte Bilder zeigen einen Platzhalter.
- System-, Light- und Dark-Theme, vier Seed-Farben, optionale Gerätefarben,
  Kilometer/Meilen und lokal gespeicherte Einstellungen.
- Versionierter JSON-Export einschließlich Fotodaten, stabilen IDs, Zeitstempeln,
  Einstellungen und Löschmarkierungen; native Teilen-/Speichern-Auswahl.
- Hero-Übergänge, dezente Einblendungen, animierte Charts, Lade- und Leerzustände.
- NavigationBar auf Smartphones, NavigationRail auf breiten Displays.

## Bewusster Umfang dieser ersten Version

Die Karte nutzt Natural Earth und zeigt Länderumrisse. Sie ist eine geografische
Übersicht, keine Straßenkarte, Adresssuche oder Navigation. In hoher Vergrößerung
sind nur gespeicherte Punkte und Verbindungen verfügbar. Über `JournalMapProvider`
kann ein Straßenkarten-Anbieter ergänzt werden. Koordinaten werden nicht in
Adressen umgerechnet; Stadt und Land werden im Formular eingegeben.

GPS wird auf ausdrücklichen Knopfdruck abgefragt. Es gibt kein Tracking im
Hintergrund. Bis zu acht Fotos pro Ort, maximal 5 MB je Foto. Die Auswahl wird
auf Mobilgeräten nach Möglichkeit auf 1600 Pixel / JPEG-Qualität 82 verkleinert.
Sembast lädt seine Datei in den Speicher; für große Fotobibliotheken sollte das
Medien-Backend auf separate Dateien bzw. Objekt-Speicher umgestellt werden.

Cloud-Sync, Konfliktauflösung und Import sind vorbereitet, aber noch nicht
implementiert. Export ist bereits funktional. Demo-Fotos sind illustrative
Reisemotive und keine exakten Fotos aller benannten Hotels/Restaurants.

## Struktur und Tests

Siehe [Architektur](docs/ARCHITECTURE.md) und [Asset-Quellen](assets/CREDITS.md).
`lib/main.dart` startet lediglich die App. Theme und Tokens liegen in `lib/app/`.

Tests prüfen Serialisierung, Datenbank-Neustarts, atomare Fehlerfälle,
Foto-Bereinigung, Löschmarkierungen, Zustand nach Fehlern, Filtergrenzen,
Koordinatenprojektion, Statistik, Export und die Kernabläufe der Oberfläche.
Der Android-Integrationstest verwendet eine getrennte temporäre Datenbank
und deterministische Foto-/Standortadapter. Die nativen OS-Dialoge werden
dadurch nicht automatisiert geprüft.

Das App-Icon wird aus eigener Kompass-Geometrie erzeugt. Die reproduzierbare
Generierung für die Asset-Kataloge liegt in `tool/generate_icons.ps1`.

Grundlagen: [Flutter Material 3](https://docs.flutter.dev/release/breaking-changes/material-3-migration),
[Riverpod](https://pub.dev/packages/flutter_riverpod),
[Sembast](https://pub.dev/packages/sembast),
[Image Picker](https://pub.dev/packages/image_picker),
[Geolocator](https://pub.dev/packages/geolocator).
