---
name: vault-manager
description: |
  Use this skill when the user references Vault documents via vault: prefix notation (e.g., "vault:ai-workflows"),
  requests searching the Vault, needs to work with Obsidian documents,
  asks about backlinks or related documents, or requests vault health information.
  Triggered on vault:document references for read-only context loading (UC1).
  Supports read-only access, document discovery, metadata extraction, backlinks, and vault health analysis.
  Keywords: vault, obsidian, vault-lookup, vault-read, vault-search, backlinks, related, orphans, deadends, unresolved, vault-health
model: sonnet
---

# Vault Manager — CLI-First

**One skill, one entry point.** Obsidian CLI (`obsidian.com`) ist Primary fuer alle Vault-Operationen. Filesystem (Glob + Read) ist Fallback wenn CLI nicht verfuegbar.

---

## Turnkey Commands (Copy-Paste Ready)

**Prinzip:** IMMER `file="<name>"` (Dokumentname ohne .md). NIEMALS Pfade. NIEMALS direkter Dateizugriff (Read/Glob/Write auf Vault).

### Read & Discovery

```bash
# Dokument lesen
obsidian.com read file="<name>"

# Dokument suchen
obsidian.com search query="<text>"

# Properties lesen
obsidian.com properties file="<name>"

# Einzelne Property lesen
obsidian.com property:read name="<key>" file="<name>"
```

### Write & Edit

```bash
# Property setzen/aendern
obsidian.com property:set file="<name>" name="<key>" value="<value>"

# Property entfernen
obsidian.com property:remove file="<name>" name="<key>"

# Content anhaengen (an Ende)
obsidian.com append file="<name>" content="<text>"

# Content voranstellen (an Anfang, nach Frontmatter)
obsidian.com prepend file="<name>" content="<text>"

# Neues Dokument erstellen
obsidian.com create name="<name>" [template="<template>"]
```

### Tags & Links

```bash
# Alle Tags mit Anzahl
obsidian.com tags all counts

# Dokumente mit bestimmtem Tag
obsidian.com tag name="<tag>" verbose

# Backlinks zu Dokument
obsidian.com backlinks file="<name>"
```

### Bases & Daily Notes

```bash
# Alle Bases listen
obsidian.com bases

# Base Query ausfuehren
obsidian.com base:query path="<base-path.base>"

# Daily Note lesen
obsidian.com daily:read

# An Daily Note anhaengen
obsidian.com daily:append content="<text>"
```

### Vault Health & System

```bash
# Vault-Info
obsidian.com vault

# Orphans / Deadends / Unresolved
obsidian.com orphans
obsidian.com deadends
obsidian.com unresolved
```

### Routing-Tabelle

| User Intent | Turnkey Command |
|-------------|----------------|
| `vault:name` | `search query="<name>"` → `read file="<name>"` |
| "suche im vault" | `search query="<text>"` |
| "zeige tags" | `tags all counts` |
| "tag X finden" | `tag name="<tag>" verbose` |
| "backlinks zu X" | `backlinks file="<name>"` |
| "property lesen" | `property:read name="<key>" file="<name>"` |
| "property aendern" | `property:set file="<name>" name="<key>" value="<value>"` |
| "fuege hinzu" | `append file="<name>" content="<text>"` |
| "exportiere als Werk" | `create name="<n>" template="<t>"` + `append` |
| "base Bewerbungen" | `base:query path="<path.base>"` |
| "daily note" | `daily:read` |
| "vault health" | `orphans`, `deadends`, `unresolved`, `vault` |
| "bearbeite" (Full Rewrite) | vault-edit.sh `<name>` (nur wenn ganzer Body ersetzt wird) |

---

## Workflow

### 1. CLI Health Check (einmal pro Session)

```bash
obsidian.com version 2>&1; echo "EXIT:$?"
```
- Exit 0 → **CLI verfuegbar**, weiter mit Turnkey Commands
- Exit != 0 → **User informieren:** "Obsidian App muss laufen. Bitte starten."
- **Kein Filesystem-Fallback.** CLI ist der einzige Zugangsweg.

### 2. Document Discovery + Loading

**Immer ueber Dokumentname, nie ueber Pfade:**
```bash
obsidian.com search query="<name>"       # Discovery
obsidian.com read file="<name>"          # Content (file= nimmt Dokumentname)
obsidian.com properties file="<name>"    # Metadata (optional)
```

### 3. Fehlerbehandlung (Self-Healing)

Bei CLI-Fehlern → **obsidian.com help** konsultieren → Syntax korrigieren → retry:

```bash
# Schritt 1: Help fuer den fehlgeschlagenen Command
obsidian.com help <command> 2>&1

# Schritt 2: Mit korrekter Syntax wiederholen
obsidian.com <command> <korrigierte-parameter>
```

**Wenn Help-basierter Retry funktioniert:** Weiterarbeiten (self-healing).
**Wenn Help-basierter Retry fehlschlaegt:** User den Fehler + help-Output melden.

**NIEMALS:**
- Parameter-Kombinationen raten oder experimentell ausprobieren
- Auf Filesystem-Zugriff ausweichen (Read/Glob/Write auf Vault-Dateien)
- Pfade konstruieren oder Vault-Pfad ermitteln (ausser fuer vault-edit.sh Full Rewrite)

---

## CLI Command Reference (Vollstaendig)

Alle Commands mit Prefix `obsidian.com`. Obsidian App muss laufen (Named Pipe).
**Bei unbekanntem Command:** `obsidian.com help` oder `obsidian.com help <command>`.

<details>
<summary>Vollstaendige CLI Reference (aufklappen bei Bedarf)</summary>

### Read & Search
```
read file=<name>
search query=<text> [path= limit= format=]
file file=<name>
files [folder= ext= total]
outline file=<name> [format=tree|md|json]
```

### Properties & Tags
```
properties [file=<name> counts sort= format=]
tags [file=<name> counts sort= format=]
tag name=<tag> [total verbose]
property:read name=<n> [file=<name>]
property:set name=<n> value=<v> file=<name>
property:remove name=<n> file=<name>
```

### Links & Vault Health
```
backlinks file=<name> [counts format=]
links file=<name> [total]
orphans [total all]
deadends [total all]
unresolved [total counts verbose format=]
aliases [file=<name> format=]
```

### Bases
```
bases
base:query path=<base-path.base> [view=<name>] [format=json]
base:views
base:create file=<base-path> [name= content=]
```

### Daily Notes
```
daily
daily:read
daily:path
daily:append content=<text>
daily:prepend content=<text>
```

### Write Operations
```
create name=<n> [content= template= overwrite]
append file=<n> content=<text>
prepend file=<n> content=<text>
move file=<n> to=<path>
rename file=<n> name=<new>
delete file=<n> [permanent]
```

### Tasks
```
tasks [file=<name> done todo status= verbose format=]
task ref=<path:line> [toggle done todo]
```

### System & Navigation
```
vault [info=name|path|files|size]
folders [folder= total]
open path=<path> [newtab]
version
plugins
bookmarks
recents
workspace
```

### Developer Tools
```
eval code="<javascript>"
diff file=<name>
history / history:list / history:read / history:restore
sync / sync:status / sync:history
web url=<url>
```

</details>

---

## Bash Scripts (Write-Ops + Complex Filters)

Scripts unter `~/.claude/skills/vault-manager/scripts/`:

| Script | Zweck | Wann nutzen |
|--------|-------|-------------|
| `vault-export.sh <fileclass> <title>` | Export zu Vault (7 Fileclass-Typen) | Session-Output exportieren |
| `vault-edit.sh <name> [content]` | Edit mit Diff + Backup | Vault-Dokument bearbeiten |
| `vault-edit.sh --path <path>` | Edit mit bekanntem Pfad (Warm-Path) | Dokument bereits im Kontext |
| `vault-base.sh <name>` | Obsidian Base Query ausfuehren | Komplexe Filter-Queries |
| `vault-base.sh --list` | Alle .base Dateien listen | Discovery |
| `vault-date.sh --last <dur>` | Date-Range Filter | Dokumente nach Datum finden |
| `vault-copy.sh <source> [target]` | Copy/Move in Vault | Dateien verschieben |

---

## Configuration

### Prerequisites
- `obsidian.com` im PATH
- Obsidian App muss laufen (CLI kommuniziert via Named Pipe)
- Kein `OBSIDIAN_VAULT` noetig (CLI liefert alles, Filesystem-Zugriff nicht vorgesehen)

### Sub-Agent-Nutzung
Sub-Agents koennen CLI direkt nutzen (Named Pipe ist OS-Level, kein env var noetig).
Kein Bootstrap oder env-Prefixing erforderlich.

### Vault-Pfad-Resolution (Scripts)
Bash-Scripts nutzen `vault-lib.sh` mit `get_vault_path()`:
1. **CLI primary:** `obsidian.com vault` → Pfad (funktioniert auch in Sub-Agents)
2. **Env fallback:** `$OBSIDIAN_VAULT` (wenn CLI nicht verfuegbar)

### Setup-Pruefung
```bash
obsidian.com vault           # CLI + App OK? (liefert auch Vault-Pfad)
ls ~/.claude/skills/vault-manager/scripts/*.sh  # Scripts vorhanden?
```

---

## Triggering

| Pattern | Aktion |
|---------|--------|
| `vault:document-name` | Document lookup + context loading |
| `vault`, `obsidian` keywords | Skill activation |
| `backlinks`, `related`, `verlinkt` | Backlink analysis |
| `orphans`, `deadends`, `vault health` | Vault-wide graph analysis |
| `tags`, `tag suche` | Tag operations |

**Wichtig:** Kein `@` Symbol — `vault:` Prefix vermeidet Kollision mit Claude Code native `@file` Completion.

---

## Kein Fallback-Modus

**Alle Vault-Operationen erfordern eine laufende Obsidian App** (CLI via Named Pipe).
Wenn Obsidian nicht laeuft → User informieren: "Bitte Obsidian starten."
Es gibt keinen Filesystem-Fallback. Kein Read/Glob/Write auf Vault-Dateien.

---

## Status

- Read: ✅ CLI search + read + properties
- Export: ✅ vault-export.sh (7 Fileclass-Typen)
- Edit: ✅ vault-edit.sh + /vault-work Command
- Search: ✅ CLI tags/tag + vault-date.sh + vault-base.sh
- Links: ✅ CLI backlinks + links
- Health: ✅ CLI orphans + deadends + unresolved + vault stats

**Strategy:** CLI+Bash Hybrid (ADR-005). CLI fuer Read/Search/Tags, Bash fuer Export/Edit/Base/Date.

Last Updated: 2026-03-05
