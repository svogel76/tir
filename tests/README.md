# Tests in Tír

Dieses Projekt nutzt **GUT (Godot Unit Test)** fuer Unit-Tests.

## Test-Runner starten

1. Godot-Projekt oeffnen.
2. Scene `res://tests/test_runner.tscn` starten.
3. GUT startet und fuehrt alle Tests unter `res://tests/unit` aus.

Der Runner ist so konfiguriert, dass:

- kein Auto-Exit erfolgt,
- eine sichtbare Zusammenfassung im GUT-UI erscheint,
- ein JUnit-Report geschrieben wird.

## Aktuelle Teststruktur

- `res://tests/unit/registry/test_item_registry.gd`
- `res://tests/unit/registry/test_animal_registry.gd`
- `res://tests/unit/registry/test_game_registry.gd`
- `res://tests/unit/registry/test_registry_validation.gd`

## Report-Dateien

Beim Lauf wird ein JUnit-Report unter `user://` erzeugt, z. B.:

- `user://gut-junit_1775646326.254.xml`

Da `junit_xml_timestamp = true` aktiv ist, entsteht pro Lauf eine neue Datei.

## `user://` auf Windows

In diesem Projekt zeigt `user://` auf:

- `C:/Users/vogel/AppData/Roaming/Godot/app_userdata/Neues Spiel/`

Dort findest du die erzeugten `gut-junit_*.xml` Dateien.

## Typische Erfolgsausgabe

Im GUT-Output sieht ein erfolgreicher Lauf z. B. so aus:

- `Scripts: 4`
- `Tests: 6`
- `Passing Tests: 6`
- `---- All tests passed! ----`

## Hinweise

- Registry-Tests verwenden absichtlich **Dummy-Resources** in `user://...` und nicht die echten Spielinhalte.
- Das macht die Tests schnell, isoliert und robust gegen Content-Aenderungen.
