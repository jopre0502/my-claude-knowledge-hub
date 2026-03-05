# Vault Access via Obsidian CLI

Gilt fuer alle Kontexte (Main-Session + Subagents). Kein paths-Filter.

Bei Vault-Referenzen ("vault:", "INBOX", "Obsidian", Vault-Dokumente lesen/suchen):

## Korrekte Commands

```bash
obsidian.com search query="<text>"                  # Volltextsuche (gesamter Vault)
obsidian.com search query="<text>" path="<folder>"  # Suche auf Ordner begrenzen
obsidian.com search query="<text>" limit=5          # Ergebnisse begrenzen
obsidian.com read file="<name>"                     # Inhalt lesen (Dokumentname, kein Pfad)
obsidian.com properties file="<name>"               # Metadata lesen
obsidian.com vault                                  # Vault-Pfad ermitteln (nur wenn noetig)
obsidian.com version                                # Health Check (einmal pro Session)
```

## Suchstrategie

- **Ordner eingrenzen:** `path="<folder>"` nutzen statt Ordnernamen als query
- **Alle Dateien in Ordner:** `search query="." path="<folder>"` (Punkt matcht alles)
- **Spezifische Keywords:** Inhaltliche Begriffe suchen, nicht Ordnernamen
- **Tag-Suche:** `search query="tag:"` funktioniert NICHT — nach Fund: `properties file="<name>"` nutzen
- **Max 2 Suchversuche:** Wenn 2 Suchen nichts finden, User fragen statt weiterprobieren

## Ordner-Aliase (User sagt → path= Wert)

| User sagt | path= |
|---|---|
| INBOX, inbox, Eingang, Eingangsordner | `00  INBOX & QUICK NOTES` |
| Projekte | `02-Projekte` |
| Ressourcen | `04 RESSOURCEN` |
| System, Templates | `09-System` |

## Verboten

- Vault-Pfade raten oder in Loops ausprobieren
- `obsidian-cli` oder andere CLI-Namen (korrekt: `obsidian.com`)
- Filesystem-Zugriff auf Vault-Dateien (Read/Glob/Write Tools)
- `--vault` oder andere erfundene Flags

## Bei Fehlern

`obsidian.com help <command>` ausfuehren, Syntax korrigieren, retry.
Kein Trial-and-Error. Kein Fallback auf Filesystem.

## Voraussetzung

Obsidian App muss laufen (CLI kommuniziert via Named Pipe).
