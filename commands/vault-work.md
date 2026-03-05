---
name: vault-work
description: Load a Vault document for editing, work with it in session, then save changes back with diff preview
model: sonnet
---

# /vault-work Command

Laedt ein Vault-Dokument, stellt es in der Session bereit, und schreibt Aenderungen mit Diff-Preview zurueck.

## Usage

```
/vault-work <dokumentname>
```

**Beispiele:**
```
/vault-work ai-workflows
/vault-work "PKM-Workflows mit Claude"
```

## Workflow

Wenn der User `/vault-work` aufruft:

### 1. Dokument laden

Finde und lade das Dokument via Obsidian CLI (Voraussetzung: Obsidian App muss laufen):

1. Falls `$ARGUMENTS` leer ist, frage den User: "Welches Dokument moechten Sie bearbeiten?"

2. **Discovery + Content laden** (CLI-only, KEIN Filesystem-Zugriff):
   ```bash
   # Suche
   obsidian.com search query="$ARGUMENTS"
   # Lesen (file= nimmt Dokumentname, NICHT Pfad)
   obsidian.com read file="$ARGUMENTS"
   ```

**Kein Fallback.** Wenn Obsidian nicht laeuft → User informieren: "Bitte Obsidian starten."

### 2. Dokument anzeigen

Zeige dem User:
- Dateiname
- Frontmatter-Metadaten (fileClass, erstellt, tags)
- Aktuellen Content

Dann frage: "Was moechten Sie an diesem Dokument aendern?"

### 3. User bearbeitet

Der User beschreibt die gewuenschten Aenderungen. Claude hilft beim:
- Ueberarbeiten von Texten
- Ergaenzen von Sektionen
- Umstrukturieren von Inhalten
- Aktualisieren von Metadaten

### 4. Aenderungen speichern — CLI-native Turnkey Commands

**Waehle den passenden Weg basierend auf der Aenderung:**

#### A) Properties aendern (einzelne Felder)
```bash
obsidian.com property:set file="<name>" name="<key>" value="<value>"
```
Fuer jede Property einzeln aufrufen. Kein Script noetig.

#### B) Content anhaengen
```bash
obsidian.com append file="<name>" content="<text>"
```
Fuer neue Sektionen am Ende des Dokuments.

#### C) Content voranstellen
```bash
obsidian.com prepend file="<name>" content="<text>"
```
Fuer neue Sektionen am Anfang (nach Frontmatter).

#### D) Full Rewrite (ganzer Body wird ersetzt)
Nur wenn der gesamte Content neu geschrieben wird — vault-edit.sh mit Dokumentname:
```bash
# Dry-Run (Diff zeigen)
echo "<neuer-content>" | ~/.claude/skills/vault-manager/scripts/vault-edit.sh --dry-run "<name>"

# Nach Bestaetigung: Real write
echo "<neuer-content>" | ~/.claude/skills/vault-manager/scripts/vault-edit.sh "<name>"
```
**Wichtig:** IMMER zuerst --dry-run. vault-edit.sh aktualisiert `modified` automatisch.

### 5. Bestaetigung

Zeige dem User:
- Zusammenfassung der Aenderungen
- Welche CLI Commands ausgefuehrt wurden

### Fehlerbehandlung (Self-Healing)

Bei CLI-Fehlern:
```bash
# Schritt 1: Help konsultieren
obsidian.com help <command>

# Schritt 2: Mit korrekter Syntax wiederholen
```

**NIEMALS:**
- Filesystem-Zugriff (Read/Glob/Write auf Vault-Dateien)
- Pfade konstruieren oder Vault-Pfad ermitteln
- Parameter raten — im Zweifel `obsidian.com help`

## Technische Details

- **Alle Operationen via `obsidian.com` CLI** (Named Pipe, Obsidian muss laufen)
- **Immer `file="<name>"`** (Dokumentname ohne .md, KEINE Pfade)
- **vault-edit.sh** nur fuer Full Rewrite (ganzer Body ersetzen)
- **Self-Healing:** Bei Fehler → `obsidian.com help` → retry

## Referenzen

- `~/.claude/skills/setup-reference/references/PKM-WORKFLOW-VAULT-MANAGER.md` - Vault-Integration-Dokumentation (Knowledge Hub)
- `~/.claude/skills/vault-manager/scripts/vault-edit.sh` - Edit-Script
- `~/.claude/commands/vault-export.md` - Export-Command (aehnliches Pattern)

---

**Erstellt:** 2026-02-10 (TASK-016)
**Aktualisiert:** 2026-03-05 (CLI-only Turnkey Commands, kein Filesystem-Fallback)
