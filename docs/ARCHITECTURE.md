# Adventure Journal · Architektur

- app: zentrales Material-3-Theme, Tokens, Router, App-Start.
- models: unveränderliche Domänenobjekte, Suche, Statistik.
- database: plattformspezifischer Datenbankstart und einmalige Beispieldaten.
- repositories: abstrakter Vertrag und transaktionale Sembast-Implementierung.
- state: Riverpod, serielle Schreibvorgänge und gemeinsamer Datenstand.
- services: Standort, Fotoauswahl, versionierter JSON-Export.
- presentation: Screens, wiederverwendbare Widgets und Kartenadapter.
- utilities: Formatierung und verständliche Fehler.

Sembast speichert auf Android/iOS in einer Datei im privaten App-Verzeichnis;
im Browser in IndexedDB. Fotos liegen als Base64 in einem separaten Store,
damit Galerie-Cache-Dateien verschwinden dürfen. Pro Ort maximal acht Fotos
mit je 5 MB. Metadaten und neue Medien werden atomar gespeichert.
Für große Bibliotheken kann das Medien-Backend später zu Dateien wechseln.

Riverpod hält nur Metadaten. Screens lesen denselben Datenstand. Persistierung
kommt vor Veröffentlichung neuer UI-Daten. Schreibvorgänge werden serialisiert.
Fehler behalten den vorherigen Zustand. GoRouter nutzt fünf persistente Zweige.
Formulare und Details liegen darüber; IDs werden aus aktuellem State aufgelöst.

UUIDs, Zeitstempel, Schema-Version und Löschmarkierungen bereiten einen Sync-Adapter
vor. Noch kein Cloud-Client, Konfliktalgorithmus oder Import. Reise-Löschen behält
Orte. Gesamtlöschen behält Einstellungen und Seed-Marker, damit keine Demo-Daten
erneut erscheinen. Export enthält Metadaten und Fotos.

Die Offline-Karte nutzt mitgelieferte Natural-Earth-Länderpolygone. Sie ist eine
Übersichtskarte, keine Straßenkarte oder Navigation. Koordinaten und Auswahl
laufen durch einen austauschbaren Adapter.
