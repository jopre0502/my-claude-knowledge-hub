# HOW-TO: ObsidianClaude

> **Generiert:** 2026-03-05 | **Quellen:** 5/7 (Decision-Log + Task-Details nicht vorhanden)

---

## Was ist dieses Projekt?

ObsidianClaude ist das Development-Projekt fuer globale Claude Code Skills und Commands zur Obsidian Vault-Integration. Es ermoeglicht, Vault-Notizen read-only als Kontext in beliebigen Projekten zu nutzen, den Vault zu durchsuchen, Session-Output zu exportieren und Vault-Dokumente strukturiert zu bearbeiten.

Das Projekt entwickelt die **Tooling-Infrastruktur** (Skills, Commands, Scripts) — es ist selbst kein Vault und enthaelt keine Vault-Daten.

---

## Architektur

### CLI+Bash Hybrid (ADR-005)

Die zentrale Architektur-Entscheidung: Obsidian CLI (`obsidian.com`) fuer Read/Search-Operationen, Bash-Scripts fuer komplexere Workflows (Export, Edit, Queries).

**Drei Ebenen:**

| Ebene | Zweck | Ort |
|-------|-------|-----|
| **Skill** (vault-manager) | Auto-triggered Read/Search via Bash | `~/.claude/skills/vault-manager/` |
| **Commands** (/vault-*) | Manuelle Operationen (Export, Edit, Backup) | `~/.claude/commands/` |
| **Vault** | Dokumente + Wissen (PARA-Struktur) | `$OBSIDIAN_VAULT/` (via CLI aufloesbar) |

**Voraussetzung:** Obsidian App muss laufen (CLI kommuniziert via Named Pipe).

### Domain Separation (Kritisch)

- Dieses Projekt (Dev-Repo) ist **nicht** der Vault
- Skills gehoeren nach `~/.claude/`, nicht in den Vault
- Keine Symlinks zwischen `~/.claude/` und Vault
- Obsidian (flat, semantisch) und Claude Code (hierarchisch, strukturell) bleiben getrennt

### Vault-Zugriff: CLI-Only Turnkey

Seit TASK-040/041 gilt: `obsidian.com` ist der **einzige** Vault-Zugang.

- `file="<name>"` fuer alles (kein Pfad noetig)
- Kein Filesystem-Fallback (kein Read/Glob/Write auf Vault-Dateien)
- Vault-Pfad: `obsidian.com vault` (CLI-first, Named Pipe)
- Self-Healing bei Fehlern: `obsidian.com help <command>`

### Propagation: Skills vs. Rules

| Mechanismus | Main-Session | Subagents |
|---|---|---|
| Skills (`~/.claude/skills/`) | Ja | NEIN |
| Rules (`~/.claude/rules/`) | Ja | JA |
| CLAUDE.md | Ja | NEIN |

Universelle Verhaltensregeln (z.B. Vault-CLI-Syntax) werden als Rule hinterlegt: `~/.claude/rules/vault-access.md`.

---

## Workflow und Konventionen

### Session-Continuous Workflow

1. **Session Start:** CLAUDE.md + PROJEKT.md lesen, `/run-next-tasks` ausfuehren
2. **Waehrend Arbeit:** Task-Status in PROJEKT.md pflegen, Audit Trail fuehren
3. **Session Ende (Token >65%):** `/session-refresh` ausfuehren, committen

### Git Konventionen

- **Commit-Format:** `[typ]: Kurzbeschreibung` (deutsch), Co-Authored-By: Claude
- **Vault-Repo:** Push-only (kein Pull/Merge, Single-User)
- **Dev-Repo:** Standard Git-Workflow
- **Sync-Commands:** `/obsidian-sync` (Vault), `/knowledge-hub-sync` (~/.claude/)

### Kritische Regeln

- **NIEMALS** `cd "$OBSIDIAN_VAULT"` in Command-Templates
- **NIEMALS** Filesystem-Zugriff auf Vault (nur CLI)
- **NIEMALS** Skills manuell erstellen (immer `/skill-creator` nutzen)
- **NIEMALS** `obsidian-cli` oder andere CLI-Namen (korrekt: `obsidian.com`)
- **Tasks** werden in PROJEKT.md + Task-Files verwaltet (nicht via TaskCreate API)

### Secrets-Handling

4-Layer Config-Architektur:
- Layer 1: `~/.config/secrets/env.d/*.env` (vault.env, n8n.env)
- Layer 4: SessionStart Hook laedt env.d automatisch
- Sub-Agents: CLI funktioniert direkt (Named Pipe), aber Secrets nur in Main-Session

---

## Aktueller Stand

**Status:** Feature-complete (Maintenance). Alle Phasen abgeschlossen.

**Abgeschlossene Phasen:**

| Phase | Inhalt | Zeitraum |
|-------|--------|----------|
| Phase 1 | UC1 Read-Only Vault-Referenz | 2026-01-15 - 2026-02-03 |
| Phase 2 | UC2 Session-Export (Fileclass) | 2026-02-03 - 2026-02-08 |
| Phase 3 | UC3 Vault-Edit (vault-edit.sh) | 2026-02-10 - 2026-02-11 |
| Phase 4 | Quick Wins (Tags, Date, Base, Copy) | 2026-02-11 - 2026-02-12 |
| Phase 5a | CLI Architecture (ADR-005) | 2026-02-13 - 2026-02-17 |
| Phase 5b | CLI Migration (12 Tasks) | 2026-02-17 - 2026-03-05 |

**Phase 6 (MCP/RAG):** Obsolet — CLI+Bash Hybrid deckt alle Usecases ab.

**Letzte abgeschlossene Tasks:**
- TASK-042: Vault Access Rule (Subagent CLI Propagation)
- TASK-041: Environment-Rueckbau (CLI-Only Vault Path)
- TASK-040: Vault Architecture Simplification (CLI-First)
- TASK-039: QMD Integration (cancelled — Embedding blockiert)
- TASK-038: Sub-Agent Env Bootstrap

---

## Bekannte Herausforderungen

### Geloest (aber beachtenswert)

- **Obsidian muss laufen:** CLI funktioniert nur bei laufender App (Named Pipe). Insider Builds AN, Auto-Update AUS.
- **Sub-Agent Isolation:** Subagents erben keine Environment-Variablen. Vault-CLI funktioniert (Named Pipe ist OS-Level), aber Secrets muessen in Main-Session aufgeloest werden.
- **Windows Git Bash Performance:** `CreateProcess` ~200ms/Call. Externe Befehle in Loops vermeiden, Bash-Builtins nutzen.
- **CRLF:** Defensive Patterns (`tr -d '\r'`, `line="${line%$'\r'}"`) beibehalten.
- **allowed-tools blockiert CLI:** Commands mit `allowed-tools: Task` koennen kein Bash. Bash muss explizit in allowed-tools stehen wenn CLI-Zugriff vor Delegation noetig.

### Keine offenen Blocker

Stand 2026-03-05: Keine offenen Issues. Projekt ist im Maintenance-Modus.

---

## Learnings und Patterns

### Bewaehrte Patterns

- **CLI+Bash Hybrid** ist die richtige Strategie — CLI fuer atomare Ops, Bash fuer Orchestrierung
- **Progressive Disclosure** fuer Skills: SKILL.md <300 Zeilen, Details in references/
- **Semantic Auto-Discovery** statt Regex-Trigger: Claude matcht Keywords aus der Skill-Description
- **`vault:` Prefix** als Trigger-Convention (ersetzt frueheres `@notation`)
- **Push-only Git** fuer Single-User Vault (kein Merge-Overhead)
- **Rules fuer Subagents:** Universelle Regeln als `~/.claude/rules/*.md` statt nur im Skill

### Was nicht funktioniert hat

- **QMD/Semantic Search (TASK-039):** BM25 funktionierte, aber Embedding via node-llama-cpp auf Windows/CPU nicht praktikabel. Cancelled.
- **MCP/RAG (Phase 6):** Ueberengineered fuer die tatsaechlichen Usecases. CLI+Bash reicht.
- **Daily Note Integration (TASK-030):** Kein ausreichender Usecase identifiziert. Cancelled.
- **Index-Dateien pflegen:** User-Entscheidung gegen Index-File, CLI-Search ist schnell genug.

### Session-uebergreifende Erkenntnisse

- `obsidian.com search query="." path="<folder>"` listet alle Dateien eines Ordners
- `path=` Parameter begrenzt Suche auf Ordner (undokumentiert, aber funktional)
- Tag-Suche via `search query="tag:"` funktioniert NICHT — nach Fund `properties` nutzen
- `git update-index --really-refresh` vor `git status` bei Filesystem-Inkonsistenzen
- Cross-Projekt-Migration: Bei Architektur-Aenderungen auch projektlokale `.claude/` anderer Projekte pruefen

---

## Quick Reference

### Wichtige Pfade

| Was | Pfad |
|-----|------|
| Dev-Projekt | `C:\Development\Projects\Claude\ObsidianClaude\` |
| Skill (vault-manager) | `~/.claude/skills/vault-manager/SKILL.md` |
| Scripts | `~/.claude/skills/vault-manager/scripts/` |
| Commands | `~/.claude/commands/` (vault-export, vault-work, obsidian-sync) |
| Rule (Vault-Zugriff) | `~/.claude/rules/vault-access.md` |
| PKM-Workflow Doku | `~/.claude/skills/setup-reference/references/PKM-WORKFLOW-VAULT-MANAGER.md` |
| PROJEKT.md | `docs/PROJEKT.md` |
| Task-Dateien | `docs/tasks/TASK-NNN-name.md` |
| Phase-Archive | `docs/phases/Phase-NN-Name.md` |

### Vault CLI Commands

```bash
obsidian.com search query="<text>"                  # Volltextsuche
obsidian.com search query="<text>" path="<folder>"  # Ordner-Scope
obsidian.com read file="<name>"                     # Dokument lesen
obsidian.com properties file="<name>"               # Metadata lesen
obsidian.com vault                                  # Vault-Pfad
obsidian.com version                                # Health Check
```

### Bash-Scripts

| Script | Funktion |
|--------|----------|
| vault-export.sh | Session-Output in Vault exportieren (7 Fileclass-Typen) |
| vault-edit.sh | Vault-Dokument bearbeiten (Diff, Backup, Frontmatter) |
| vault-base.sh | Base Query (.base File Parsing) |
| vault-date.sh | Date-Range Filter |
| vault-copy.sh | Dateien in Vault kopieren/verschieben |
| vault-lib.sh | Shared Helper (get_vault_path) |

### Slash Commands

| Command | Zweck |
|---------|-------|
| `/vault-export` | Export Session-Output in Vault |
| `/vault-work` | Vault-Dokument laden, bearbeiten, zurueckschreiben |
| `/obsidian-sync` | Vault zu GitHub pushen |
| `/knowledge-hub-sync` | ~/.claude/ zu GitHub pushen |
| `/run-next-tasks` | Ready Tasks anzeigen |
| `/session-refresh` | Session-Ende: Docs updaten + optimieren |

---

*Generiert aus: CLAUDE.md, PROJEKT.md, Session-Handoff s48, Auto-Memory, Phase-3-Archiv*
