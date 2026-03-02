# Claude Code + Knowledge Hub — Cheatsheet

> Zum Ausdrucken. Haengen Sie es neben Ihren Monitor.

---

## Die 3 wichtigsten Befehle

| Befehl | Wann | Was passiert |
|--------|------|--------------|
| `/project-init` | Neues Projekt starten | Erstellt CLAUDE.md + PROJEKT.md + Task-Struktur |
| `/run-next-tasks` | Session-Start | Zeigt welche Tasks bereit sind |
| `/session-refresh` | Session-Ende oder Token >65% | Aktualisiert + komprimiert Dokumentation |

---

## Session-Workflow (jedes Mal)

```
START                          ARBEITEN                    ENDE
  |                               |                         |
  v                               v                         v
claude starten              Task bearbeiten          /session-refresh
  |                               |                         |
/run-next-tasks             Status updaten           git commit
  |                               |                         |
Ersten Ready-Task            Token >65%?             /exit
  starten                   → /session-refresh
```

---

## Dateien die Claude liest

| Datei | Wo | Was | Wer aendert |
|-------|----|-----|-------------|
| `~/.claude/CLAUDE.md` | Global | Ihre persoenlichen Regeln | Sie (einmalig + selten) |
| `CLAUDE.md` | Im Projekt | Projekt-Architektur | Claude + Sie |
| `docs/PROJEKT.md` | Im Projekt | Task-Tabelle + Status | Claude (via Skills) |
| `docs/tasks/TASK-NNN-*.md` | Im Projekt | Task-Details + Audit Trail | Claude + Sie |

---

## Hilfe holen

| Frage | Methode |
|-------|---------|
| "Welche Skills gibt es?" | `/help` oder `my-setup-guide` fragen |
| "Wie mache ich X?" | `Frage den my-setup-guide: Wie mache ich X?` |
| "Was war der letzte Stand?" | `/run-next-tasks` |
| "Etwas funktioniert nicht" | `/help` → Troubleshooting |

---

## Token-Budget (die Statusleiste unten)

| Anzeige | Bedeutung | Aktion |
|---------|-----------|--------|
| < 50% | Alles gut | Weiterarbeiten |
| 50–65% | Wird eng | Beobachten |
| 65–70% | Warnung | `/session-refresh` ausfuehren |
| >70% | Kritisch | Sofort `/session-refresh`, dann Session beenden |

---

## Die goldene Regel

> **Die KI ist so gut wie die Struktur, die der Mensch ihr gibt.**

Konkret:
- Gute CLAUDE.md schreiben (praezise, nicht lang)
- PROJEKT.md aktuell halten (Claude hilft dabei)
- Sessions sauber beenden (`/session-refresh`)
- Ein Projekt nach dem anderen (nicht parallel)

---

## Kosten

| Plan | Preis | Fuer wen |
|------|-------|----------|
| Pro | $20/Monat | Einstieg, limitiert |
| Max | $100/Monat | Produktive Nutzung |
| Team | $30/User/Monat | Teams, nur CLI |

---

## Nuetzliche Tastenkombinationen

| Taste | Funktion |
|-------|----------|
| `Ctrl + Backtick` | Terminal in VS Code oeffnen |
| `Ctrl + C` | Claude Code abbrechen |
| `Escape` | Aktuelle Eingabe abbrechen |
| `/exit` | Session beenden |
| `/help` | Alle Befehle anzeigen |
| `/clear` | Konversation zuruecksetzen |

---

*TASK-000 Artifact | Version 1.0 | 2026-03-02*
