# Vault Access via Obsidian CLI

Gilt fuer alle Kontexte (Main-Session + Subagents). Kein paths-Filter.

Bei Vault-Referenzen ("vault:", "INBOX", "Obsidian", Vault-Dokumente lesen/suchen):

## Korrekte Commands

```bash
obsidian.com search query="<text>"       # Dokumente finden
obsidian.com read file="<name>"          # Inhalt lesen (Dokumentname, kein Pfad)
obsidian.com properties file="<name>"    # Metadata lesen
obsidian.com vault                       # Vault-Pfad ermitteln (nur wenn noetig)
obsidian.com version                     # Health Check (einmal pro Session)
```

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
