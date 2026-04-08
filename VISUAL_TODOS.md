# Tír – Visual Todos
*Offene Punkte für spätere Iterationen*

---

## Beleuchtung & Sky

**Mondphasen-System**
`Moonlight Max Strength` ist aktuell ein fester Wert (0.06).
Wenn das Mondphasen-System steht:
- Vollmond → `0.08` (kaum Hilfe, aber sichtbar)
- Halbmond → `0.04`
- Neumond → `0.0` (vollständige Dunkelheit – Darkness is a mechanic)
Mondphase als Wert in `SeasonDefinition` oder eigenem `CalendarSystem`.

**Sonnenaufgang Warmton**
Der Übergang von Nacht zu Tag könnte dramatischer sein –
ein kurzer intensiver Moment wo der Horizont tiefrot leuchtet
bevor das Tageslicht einsetzt. Aktuell ist der Übergang zu gleichmäßig.

**Wolken**
Der Himmel ist aktuell wolkenlos.
Ghibli-Wolken: weiße Cumulus-Wolken mit hartem Cel-Rand,
langsam über den Himmel ziehend.
Godot `ProceduralSkyMaterial` unterstützt keine Wolken nativ –
eigene Wolken-Meshes oder ein Wolken-Shader nötig.
Wettersystem-Vorbereitung: Wolkendichte beeinflusst Mondlicht und Tageslicht.

**Sterne**
Nachts ist der Himmel aktuell einfarbig dunkelblau.
Ein Sternen-Layer für klare Nächte – Partikel oder Shader-basiert.
Mondphase und Bewölkung bestimmen Sichtbarkeit.
Zu Samhain: mehr Sterne, andere Konstellation.

**Nebel in Tälern**
Das Referenzbild zeigt Morgennebel der in den Tälern liegt.
Volumetrischer Nebel der tief liegende Gebiete füllt –
morgens stark, mittags aufgelöst.
Godot 4 hat Volumetric Fog nativ – noch nicht konfiguriert für Talsohlen.

---

## Terrain & Shader

**Slope-Färbung Fels/Erde**
Die slope-basierte Färbung im `terrain_cel.gdshader` ist implementiert
aber visuell kaum sichtbar – steile Hänge zeigen noch kein Erdbraun/Felsgrau.
Schwellenwerte und Farben nachschärfen sobald Bodendeck steht
(Fels soll dort sichtbar sein wo kein Gras wächst).

**Terrain-Textur-Detail**
Aktuell rein farbbasiert ohne Textur.
Für spätere Iteration: leichte Noise-Textur die Grasstruktur andeutet –
nicht photorealistisch, aber mehr Tiefe als reine Farbe.

**Wasser**
Flüsse, Seen, Moorland – noch nicht implementiert.
Wasser im Cel-Stil: flache blaue Fläche mit Cel-Rand,
leichte Bewegungsanimation im Shader.
Erle wächst am Wasser – Biom-Logik nötig.

**Schnee im Winter**
`SeasonDefinition` hat `season_index` – Winter (3) sollte
das Terrain visuell verändern: weiße Schneedecke auf flachen Flächen,
Schneehauben auf Baumkronen.
Shader-Parameter die saisonal umgeschaltet werden.

---

## Vegetation

**Bodendeck** *(nächster Schritt)*
Hohes Wiesengras, Wildblumen (gelb/weiß), moosbewachsene Felsbrocken.
Siehe Referenzbild (Idyllische_Landschaft_mit_alten_Bäumen.png).

**Windanimation**
Gras und Baumkronen sollen im Wind bewegen.
Shader-basierte Windanimation – Vertex-Displacement in GDShader.
Windstärke koppeln an Wettersystem wenn es steht.

**Baumkronen-Verbesserung**
Aktuelle Kronen sind zu gleichmäßig rund.
Für alte Eichen: unregelmäßigere Knotenstruktur,
Äste die durch die Krone ragen, asymmetrische Form.
Orientierung am Referenzbild – breite ausladende Krone, nicht Kugel.

**Weitere Baum-Typen**
Aktuell nur Eiche implementiert.
Geplant laut Konzept: Eibe, Esche, Erle, Birke –
jeder Typ hat eigenen visuellen Charakter und Cel-Shader-Variante.
Birke: weiße Rinde, helle Krone.
Eibe: dunkel, dicht, fast schwarz-grün.

**Saisonale Vegetation**
Bäume sollen im Herbst braun-rote Blätter zeigen, im Winter kahl sein.
Shader-Parameter saisonal steuern über DayNightCycle/SeasonSystem.

**Unterholz**
Zwischen den Bäumen: Büsche, Farne, Brombeersträucher.
Dichter Unterholz macht den Wald undurchdringlich – Gameplay-Relevanz
(du kannst nicht einfach durch den Wald laufen).

---

## Otherworld – An Caol Áit

**Visueller Übergangseffekt**
Der Übergang zur Anderswelt hat noch keinen visuellen Effekt.
Konzept: Licht wird "älter", Farben verschieben sich ins Unwirkliche,
Konturen werden unscharf dann wieder scharf aber anders.
Kein Ladebildschirm – der Übergang passiert während du spielst.

**Anderswelt-Shader**
Die Anderswelt braucht einen eigenen visuellen Stil:
- Bäume die gefällt wurden stehen wieder
- Licht aus falscher Richtung
- Farben leicht invertiert oder gesättigt ins Unwirkliche
- Post-Processing Effekt der subtil über die normale Szene gelegt wird

**Pilzkreise (Hexenringe)**
Visuell erkennbar aber nicht offensichtlich –
ein Kreis aus Pilzen der im hohen Gras fast versteckt ist.
Leichtes Leuchten nachts.

**Steinkreis-Atmosphäre**
Steinkreise brauchen eigenen visuellen Charakter:
- Moos auf den Steinen
- Leichtes Flimmern/Hitzewellen-Effekt wenn Anderswelt naht
- Ogham-Inschriften auf den Steinen (Textur)

---

## Post-Processing & Effekte

**Vignette**
Leichte Vignette an den Bildrändern – erhöht Immersion,
gibt dem Cel-Stil mehr Tiefe.
Stärker nachts, fast unsichtbar mittags.

**Kälte-Overlay**
Blaue Vignette wenn der Spieler unterkühlt ist –
bereits im Konzept erwähnt, noch nicht implementiert.
Stärker je kälter, pulst leicht.

**Anderswelt-Overlay**
Subtiler visueller Effekt wenn Spieler in der Nähe einer
dünnen Stelle ist – kaum wahrnehmbar, aber spürbar.

---

## Performance

**LOD für Vegetation**
Bäume und Bodendeck in der Ferne vereinfachen.
Godot `VisibilityNotifier3D` oder manuelles LOD-System.
Besonders wichtig wenn Bodendeck dicht wird.

**Instancing für Vegetation**
Gras und Blumen als `MultiMeshInstance3D` –
tausende Instanzen ohne Performance-Einbruch.
TreePlacer bereits als Grundlage, Bodendeck sollte
von Anfang an auf MultiMesh aufbauen.

---

*Erstellt während der Vegetation/Beleuchtungs-Implementierung · April 2026*
