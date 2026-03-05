# HOW-TO: projekt-automation-hub

> **Generiert:** 2026-03-05 | **Quellen:** 7/7

---

## Was ist dieses Projekt?

**Development-Zentrum** fuer globale Claude Code Elemente (Skills, Agents, Commands, Hooks). Neue Feature-Ideen mit globaler Auswirkung werden IMMER hier entwickelt und getestet, bevor sie nach `~/.claude/` deployed werden. Das Projekt ist gleichzeitig Meta-Projekt zur Optimierung von PROJEKT.md und Skill-Interoperabilitaet.

**Disziplin-Regel:** Globale Features immer hier entwickeln — nicht direkt in `~/.claude/` editieren.

---

## Architektur

### Three-Tier Dokumentationsmodell

| Ebene | Datei | Zweck |
|-------|-------|-------|
| Architecture Guide | `CLAUDE.md` (Root) | Projektarchitektur, Session-Workflow, Konventionen. Ziel: < 8KB |
| Central Hub (SSOT) | `docs/PROJEKT.md` | Aktiver Projektstand, 7-Column Task Schema. Ziel: 8-12K Zeichen |
| Audit Trail | `docs/tasks/TASK-NNN-name.md` | Detaillierte Task-Dokumentation mit Frontmatter |

### 7-Column Task Schema

```text
| UUID | Task | Status | Dependencies | Effort | Deliverable | Task-File |
```

Status-Werte: pending, in_progress, ongoing, completed, blocked, cancelled. Wird von `task-scheduler` (`/run-next-tasks`) maschinell geparst — Struktur darf nicht geaendert werden.

### Task-File-Struktur

```text
docs/tasks/
  TASK-NNN-name.md          <- Task-Dokument DIREKT hier
  TASK-NNN/                 <- Output-Ordner (nur Logs/Artifacts)
    execution-logs/
    artifacts/
```

### Phasen-Archivierung

Abgeschlossene Tasks werden nach `docs/phases/Phase-NN-*.md` ausgelagert, um PROJEKT.md unter 12K Zeichen zu halten. Der Health-Check behandelt fehlende Dependencies als "archived/completed".

---

## Workflow & Konventionen

### Session-Continuous Workflow

```text
START:
  1. CLAUDE.md + PROJEKT.md lesen (automatisch via Handoff-Injection)
  2. /run-next-tasks → Ready Tasks identifizieren
  3. Ersten Ready Task starten

WAEHREND:
  4. Task-File + PROJEKT.md Status aktualisieren
  5. Token > 65%? → /session-refresh

ENDE (automatisch, ohne Rueckfrage):
  6. Final Commit (deutsche Message) + Session-Handoff schreiben
```

### Kritische Regeln

- **Action-Pacing:** Nach JEDER Action den User fragen. NIEMALS mehrere Actions ohne Rueckfrage. Ausnahme: Session-Ende (Commit + Handoff) laeuft automatisch.
- **Max Actions pro Session:** 1-2 bei file-intensiven Tasks, bis zu 3 bei leichten.
- **Autocompacting ist ein Fail-State.** Token-Budget proaktiv managen.
- **Commits:** Deutsche Commit-Messages, Format `[Typ]: Kurzbeschreibung`. Co-Authored-By: Claude.
- **NIEMALS:** `--force` auf main, `--no-verify`, Tasks API (TaskCreate etc. ist blockiert).

### SSOT-Prinzip

PROJEKT.md ist die **einzige Wahrheit** fuer Task-Management. Keine Claude Tasks API, keine TodoWrite. Task-Tracking ueber `/task-orchestrator`, `/run-next-tasks`, 7-Column Schema.

---

## Aktueller Stand

**Phase 2: Operative Nutzung + Continuous Improvement** (aktiv seit Phase 1 abgeschlossen)

- Phase 1 (Foundation): 19 Tasks, alle abgeschlossen — Three-Tier-Architektur, 7-Column Schema, Template-Sync, Session-Handoff
- Phase 2: 38+ Tasks abgeschlossen, 2 cancelled

**Letzte abgeschlossene Tasks:**

- TASK-069: Restructure Skills Hardening — details-Detection + Groessen-Metrik
- TASK-068: Knowledge Hub README Drift-Check
- TASK-067: Public Repo Professionalisierung my-knowledge-hub
- TASK-066: macOS-Kompatibilitaet my-knowledge-hub
- TASK-065: SSH-Auth fuer Vault via 1Password
- TASK-064: details-Tag Elimination in Skills + Templates
- TASK-063: Systemweiter CRLF-Fix (LF-Policy + Verifikation)
- TASK-053: Claude Code Migration WSL2 → Native Windows (6 Phasen)

**In Arbeit:**

- TASK-070: Skill `/generate-pwd-howto` — Actions 1-5 done, Erstgenerierung laeuft

**Naechster Ready Task:**

- TASK-052: Spike Telegram Integration (pending, keine Dependencies)

---

## Bekannte Herausforderungen

### Aktive Issues

| Issue | Schwere | Status |
|-------|---------|--------|
| CLAUDE_ENV_FILE: Vars nicht in Bash sichtbar (Bug #15840) | Mittel | Workaround aktiv: `.env-cache` wird bei Session-Start geschrieben |
| Metriken (TTO, SCI, CLS, DocDebt) ohne Messmethodik | Mittel | Als Orientierungswerte labeln |

### Wiederkehrende Patterns aus Handoffs

- **Windows Git Bash Performance:** CreateProcess() ~200ms pro Subprozess. Keine externen Befehle in Loops. Bash-native Operationen nutzen (`${var%/*}` statt `$(dirname)`).
- **CRLF auf Windows:** jq-Output immer `| tr -d '\r'`, Datei-Input `line="${line%$'\r'}"`. Defensive Patterns NICHT entfernen.
- **grep -oP vs -oE:** Perl-Regex (-oP) in Git Bash kann Locale-Probleme haben. Extended Regex (-oE) ist sicherer.
- **Subagent Isolation:** Task-Subagents erben KEINE Environment-Variablen. API-Calls mit Secrets in Main-Session ausfuehren.
- **Google Drive desktop.ini:** Erstellt desktop.ini in `.git/` Unterordnern → Fetch/Push bricht. Fix: `find .git -name "desktop.ini" -delete`.

---

## Learnings & Patterns

### Bewaehrte Patterns

- **Prompt-Only Skills:** Wenn die AI das Werkzeug ist (lesen, analysieren, generieren), kein Bash-Script noetig. SKILL.md enthaelt die Anleitung als Prompt.
- **Pipe-Elimination auf Windows:** projekt-health-check.sh 104s → 1.4s (75x Speedup) durch native Bash-Operationen.
- **Cross-Skill Output:** Wenn ein Skill in das Verzeichnis eines anderen schreibt, bewusste Integration dokumentieren.
- **Obsidian CLI:** `obsidian.com` nutzt Named Pipe (OS-Level) → funktioniert in Subagents ohne env vars. Colon-Commands funktionieren nativ seit neuem Installer.
- **SSH via 1Password:** Keys bleiben in 1Password. KEIN expliziter IdentityAgent in ssh config auf Windows (ueberschreibt internen Pfad).
- **Knowledge Hub:** `~/.claude/` wird via Git getrackt (Whitelist-.gitignore: `*` + explizite `!` Whitelists). Push via `/knowledge-hub-sync`.
- **Session-Ende:** Commit + Handoff IMMER automatisch. Commit direkt in Main Session (beste Commit-Message-Qualitaet).

### Anti-Patterns (vermeiden)

- `<details>` Tags in Markdown (Claude Code rendert sie nicht, verhindert Scanning)
- Monolith-Agents die nur Skills wrappen (Drift-Risiko)
- `secret-run` (WSL2-Relikt, deprecated)
- MCP fuer Skill-Export (Over-Engineering fuer Workflow-Orchestrierung)
- TaskCreate/TodoWrite API (konkurriert mit PROJEKT.md SSOT)

---

## Wichtige Entscheidungen

| # | Entscheidung | Datum | Impact |
|---|-------------|-------|--------|
| 65 | Google Drive desktop.ini Cleanup in Vault .git/ | 2026-03-04 | Fetch/Push funktioniert wieder |
| 64 | SSH-Auth Vault via 1Password SSH Agent | 2026-03-04 | Key-basierte Auth, kein Token-Rotation |
| 63 | CRLF-Fix Pipeline statt Bulk | 2026-03-03 | 3-Ebenen-Praevention, auditierbar |
| 62 | Completed Tasks Archivierung + Health-Check Fix | 2026-03-02 | PROJEKT.md 55% kleiner |
| 60 | Windows Bash Pipe-Elimination Pattern | 2026-03-02 | 75x Speedup, gilt als Pattern |
| 59 | TASK-000 Onboarding als Genesis-Task | 2026-03-02 | Jeder neue User trifft darauf |
| 41 | SATE Architecture | 2026-02-16 | Session-Autonome Task Execution |
| 34 | Permission Global Allowlist | 2026-02-11 | ~95% weniger Permission-Prompts |
| 36 | Session-Start Handoff-Injection | 2026-02-11 | ~0 Setup bei Session-Start |
| 23 | Export-Strategie: Hybrid Plugin-Repo | 2026-02-09 | 3 thematische Plugin-Bundles |

> Vollstaendiger Decision Log: `docs/DECISION-LOG.md` (65 Eintraege)

---

## Quick Reference

### Wichtige Pfade

| Pfad | Beschreibung |
|------|-------------|
| `CLAUDE.md` | Architecture Guide (Root) |
| `docs/PROJEKT.md` | Active Task Hub (SSOT) |
| `docs/tasks/TASK-NNN-name.md` | Task-Dokumente |
| `docs/handoffs/SESSION-HANDOFF-*.md` | Session Handoffs (~85 Stueck) |
| `docs/DECISION-LOG.md` | Architectural Decisions (65 Eintraege) |
| `docs/phases/Phase-01-Foundation.md` | Abgeschlossene Phase 1 |
| `docs/phases/Phase-02-Completed-Tasks.md` | Archivierte Phase-2 Tasks |
| `~/.claude/skills/` | Produktive Skills (deployed) |
| `~/.claude/hooks/` | Produktive Hooks |

### Kern-Skills fuer dieses Projekt

| Skill | Zweck |
|-------|-------|
| `/run-next-tasks` | Task-Dependencies aufloesen (Session-Start) |
| `/session-refresh` | Docs aktualisieren + optimieren (Session-Ende) |
| `/task-orchestrator` | Strukturierte Task-Ausfuehrung |
| `/project-doc-restructure` | PROJEKT.md Inverted Pyramid |
| `/claude-md-restructure` | CLAUDE.md < 8K optimieren |
| `/generate-pwd-howto` | Dieses Dokument generieren |
| `/refresh-reference` | Setup-Inventar aus Live-System |
| `/knowledge-hub-sync` | Knowledge Hub zu GitHub pushen |
| `/prioritize-tasks` | Tasks nach Priority-Score ordnen |

### Statistiken

- **Sessions:** 127+ (seit Januar 2026)
- **Tasks gesamt:** ~70 (57+ completed, 2 cancelled, 1 in_progress, 1 pending)
- **Handoffs:** ~85 Session-Handoff-Dokumente
- **Entscheidungen:** 65 im Decision Log
- **Phasen:** Phase 1 (Foundation) done, Phase 2 (Operative Nutzung) aktiv
