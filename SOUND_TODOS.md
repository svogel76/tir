# Tír – Sound Todos
*Offene Punkte für spätere Iterationen*

---

## Fehlende Audio-Assets

Folgende Sound-Kategorien sind im System vorbereitet aber noch ohne Assets:

**Tier-Sounds**
Für jeden Tier-Typ (Hirsch, Wildschwein, Wolf) werden benötigt:
- Idle-Sounds (ambient, gelegentlich)
- Alert-Sounds (Tier hat Spieler bemerkt)
- Flucht-Sounds (Tier flieht)
- Tod-Sounds (nach Erlegung)

Die SoundProfile-Resources (`deer_sound_profile.tres` etc.) existieren bereits –
AudioStream-Felder sind leer und müssen befüllt werden.

**Ort-Sounds (Schicht 3)**
- Steinkreis: leises Summen/Brummen
- Fluss/Bach: Wasserrauschen
- Höhle: Tropfen, Hall
- Lagerfeuer: Knistern, Prasseln

**Anderswelt-Sounds**
- Verkehrter Vogelgesang (rückwärts)
- Tiefe Drohnen
- Obertongesang in der Ferne
- "Wasser das bergauf fließt" – texturaler Klangteppich

**Interaktions-Sounds**
- Baum fällen (Axt-Schläge, Knacken, Fall)
- Ressourcen sammeln (Kräuter, Steine)
- Feuer anzünden (Reiben, erstes Knistern)
- Inventar öffnen/schließen (Leder, Schnallen)

**Wetter-Sounds**
- Regen (leicht, stark)
- Wind (Brise, Sturm)
- Donner (fern, nah)

---

## Offene System-Features

**Crossfade zwischen Tageszeiten**
Aktuell werden Sounds per Tageszeit-Fenster ein/ausgeblendet.
Ein echter Crossfade der zwei Tageszeit-Schichten überblendet
wäre atmosphärisch überzeugender – besonders Morgen/Abend-Übergang.

**Wetter-Integration**
AudioManager kennt noch keine Wetterzustände.
Wenn das Wettersystem steht: Regen/Wind-Sounds als eigene Schicht
die das Wetter-System steuert, nicht der Tageszeit-Zyklus.

**Tiere in der Welt hörbar machen**
Tier-Nodes existieren noch nicht.
Wenn Tiere platziert werden: `AudioManager.register_entity_sound()`
pro Tier aufrufen und SoundProfile verwenden.
Tiere die der Spieler hört aber nicht sieht – das ist Gameplay-Information.

**Mondphasen-Audio**
Die Konzeptdokumentation erwähnt Mondphasen als Mechanik.
Vollmond könnte die Nacht-Sounds verändern – mehr Aktivität,
andere Tiere hörbar. Infrastruktur ist vorbereitet aber nicht implementiert.

**Keltische Feste**
Samhain, Imbolc, Beltane, Lughnasadh haben eigene Stimmungen.
Samhain insbesondere: alle Anderswelt-Sounds verstärkt,
progressive Stille tritt früher und stärker ein.
SeasonDefinition.celtic_festival Feld existiert – Audio-Reaktion fehlt.

**Reverb-Zonen**
Höhlen und enge Schluchten sollten Hall erzeugen.
Godot AudioServer unterstützt Bus-Effekte – ein Reverb-Bus
der in bestimmten Gebieten aktiviert wird.

**Stille als messbares Signal**
Die Anderswelt-Fade-Mechanik funktioniert technisch.
Aber es gibt kein System das *reagiert* wenn die Stille eintritt –
z.B. Spieler-Feedback, visuelle Überlagerung, Otherworld-Trigger.
Das kommt mit der Anderswelt-Implementierung.

---

## Audio-Bus Struktur (ausstehend)

Aktuell existiert nur der `Ambient` Bus.
Vollständige Struktur für später:

```
Master
├── Ambient       ✓ vorhanden
├── Animals       – fehlt
├── World         – fehlt (Ort-Sounds, Wetter)
├── Player        – fehlt (Schritte, Interaktion)
├── Otherworld    – fehlt (eigener Bus mit Effekten)
└── UI            – bewusst leer (kein UI-Sound in Tír)
```

---

## Hinweise für die Implementierung

- Alle Tier-Sounds müssen `AudioStreamPlayer3D` verwenden – nie 2D
- Schritte des Spielers sind diegetisch – Untergrundmaterial bestimmt den Klang
- Kein Sound darf aus einer unsichtbaren UI-Schicht kommen
- Stille ist immer bedeutungsvoll – nie aus Versehen Stille erzeugen

---

*Erstellt während der Audio-System Implementierung · April 2026*
