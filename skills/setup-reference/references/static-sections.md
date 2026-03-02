## Bekannte Design-Regeln

1. **NIEMALS `cd "$OBSIDIAN_VAULT"`** in Command-Templates (CWD Cross-Over Bug)
2. **NIEMALS Secrets in Shell-Init** (`.bashrc`, `.zshrc`) — nur in `env.d/*.env` (SOPS+age verschluesselt)
3. **NIEMALS `vault:` Referenzen an Subagents** weiterreichen (Environment-Isolation)
4. **IMMER `git update-index --really-refresh`** vor `git status` auf 9P/WSL2-Mounts (WSL2-only, auf Native Windows nicht noetig)
5. **IMMER Obsidian Installer + App synchron halten** (Shim-Inkompatibilitaet)
6. **SSOT fuer Tasks ist PROJEKT.md** — nicht die Built-in Task API (deaktiviert)
7. **Skills < 500 Zeilen** — Details in `references/` Unterordner
8. **Phase 6 (MCP/RAG) ist obsolet** — CLI+Bash Hybrid deckt alle Usecases ab

---

## Config-Architektur (4 Layers)

```
Layer 1: SECRETS    -> ~/.config/secrets/env.d/*.env (SOPS+age verschluesselt: vault.env, n8n.env, obsidian.env)
Layer 2: GLOBAL     -> ~/.claude/skills/, ~/.claude/CLAUDE.md, ~/.claude/agents/
Layer 3: PROJECT    -> <PWD>/.claude/, <PWD>/CLAUDE.md, <PWD>/PROJEKT.md
Layer 4: SESSION    -> CLAUDE_ENV_FILE (SessionStart Hook, aktuell Bug #15840)
```

**Injection:** SessionStart Hook `session-env-loader.sh` liest `env.d/*.env` und schreibt in CLAUDE_ENV_FILE.
**Known Issue:** CLAUDE_ENV_FILE wird aktuell nicht von Claude Code bereitgestellt (Bug #15840). Workaround: manuelles `source`.

---

## Subagent-Isolation (Kritisch)

Sub-Agents (Task tool) erben KEINE Environment-Variablen aus dem SessionStart Hook.
- `vault:` Referenzen MUESSEN in der Main-Session aufgeloest werden
- Secrets in Main-Session lesen, Klartext an Subagent uebergeben
- Oder: `source ~/.config/secrets/.env-cache` in Bash (Workaround fuer Bug #15840)
- ~~`secret-run`~~ Deprecated (WSL2-Relikt, nie auf Windows portiert) — stattdessen SOPS+age + .env-cache

---

## Session-Continuous Workflow (Kurzreferenz)

```
START  -> Lese CLAUDE.md + PROJEKT.md -> /run-next-tasks -> Starte Ready Task
ARBEIT -> Update Task-Files + PROJEKT.md Status -> Token >65%? -> /session-refresh
ENDE   -> Commit -> /session-refresh -> Optional: Session-Handoff
```

---

## Dokumentations-Architektur (Drei Ebenen)

| Ebene | Datei | Inhalt |
|-------|-------|--------|
| Architecture | CLAUDE.md | Architektur, Decisions, Standards |
| Active State | PROJEKT.md | Task-Tabelle, Phase-Status, Known Issues |
| Audit Trail | docs/tasks/TASK-NNN-name.md | Detail pro Task, Acceptance Criteria |
| Handoffs | docs/handoffs/SESSION-HANDOFF-*.md | Session-Uebergabe (narrativ) |

---

## Secrets Management (SOPS+age)

**Verschluesselung:** Alle `env.d/*.env` Dateien sind mit [SOPS](https://github.com/getsops/sops) + [age](https://github.com/FiloSottile/age) verschluesselt.

**Key-Datei:** `~/.config/secrets/age-key.txt` (SOPS_AGE_KEY_FILE)

**Alltags-Befehle:**
```
sops edit ~/.config/secrets/env.d/vault.env    # Bearbeiten (entschluesselt in $EDITOR, verschluesselt beim Speichern)
sops -d ~/.config/secrets/env.d/vault.env      # Decrypt (stdout)
sops -e plaintext.env > encrypted.env          # Encrypt
```

**SessionStart-Workflow:**
```
Session startet → session-env-loader.sh Hook
  → Liest env.d/*.env → sops -d (decrypt)
  → Schreibt CLAUDE_ENV_FILE (ideal) ODER .env-cache (Fallback Bug #15840)
  → Ergebnis: Secrets als Env-Vars in Session verfuegbar
```

**Bash-Zugriff (Workaround Bug #15840):**
```bash
source ~/.config/secrets/.env-cache
```

**Erweiterte Dokumentation:** HOW-TO-PROJEKT-AUTOMATION.md (Section: Secrets Management)

---

## Windows/MINGW-Kompatibilitaet

**Erkennung:** `session-env-loader.sh` prueft `uname -s` auf `MINGW*` oder `MSYS*`.

**SOPS-Pfade:** SOPS unter MINGW/Git Bash versteht keine Unix-Pfade (`/c/Users/...`). Daher:
- `cygpath -w` konvertiert: `/c/Users/Jonas/.config/...` → `C:\Users\Jonas\.config\...`
- `SOPS_AGE_KEY_FILE` wird automatisch konvertiert
- Jeder `sops -d` Aufruf nutzt `sops_path()` Helper

**Pfad-Konventionen:**
| Kontext | Format | Beispiel |
|---------|--------|----------|
| Git Bash / MINGW | `/c/Users/...` | `/c/Users/Jonas/.config/secrets/` |
| SOPS / Windows-Tools | `C:\Users\...` | `C:\Users\Jonas\.config\secrets\` |
| WSL2 (alt) | `/mnt/c/Users/...` | `/mnt/c/Users/Jonas/.config/secrets/` |

**Automatische Translation:** `session-env-loader.sh` ersetzt `/mnt/c/` → `/c/` auf MINGW-Plattformen.

---

## Obsidian Vault-Integration

**Architektur:** CLI+Bash Hybrid (ADR-005)
- **CLI (Obsidian 1.12+)**: search, read, properties, tags, backlinks, vault health
- **Bash-Scripts**: vault-export.sh, vault-edit.sh, vault-base.sh, vault-date.sh, vault-copy.sh
- **Voraussetzung**: Obsidian App muss laufen (CLI kommuniziert via Named Pipe)

**Vault-Pfad:** `~/.config/secrets/env.d/vault.env` als `OBSIDIAN_VAULT="..."`.

**Use Cases:**
| UC | Funktion | Trigger |
|----|----------|---------|
| UC1 | Read-Only Vault-Referenz | `vault:dokumentname` |
| UC2 | Session-Export in Vault | `/vault-export` |
| UC3 | Vault-Dokument bearbeiten | `/vault-work` |
