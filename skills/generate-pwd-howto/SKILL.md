---
name: generate-pwd-howto
description: >
  Generiert projektspezifische HOW-TO Dokumente als Onboarding-Referenz.
  Liest PWD-Daten (CLAUDE.md, PROJEKT.md, Handoffs, Memory, Decision-Log,
  Tasks, Phases) und erzeugt eine konsolidierte Projekt-Dokumentation.
  Keywords: HOW-TO generieren, Projekt-Uebersicht, Onboarding-Dokument.
disable-model-invocation: true
---

# PWD HOW-TO Generator

Generiert ein projektspezifisches HOW-TO Dokument aus den Daten des aktuellen Working Directory.

## Workflow

### Schritt 1: Projekt-Name ermitteln

1. Lies `$PWD/CLAUDE.md` und extrahiere den Projektnamen aus dem Titel oder "Projekt-Zweck" Abschnitt
2. Fallback: basename des PWD in UPPERCASE (z.B. `projekt-automation-hub` → `PROJEKT-AUTOMATION-HUB`)
3. Merke den Namen fuer den Dateinamen: `HOW-TO-<PROJECT-NAME>.md`

**Abbruch-Bedingung:** Wenn weder `$PWD/CLAUDE.md` noch `$PWD/PROJEKT.md` (oder `$PWD/90_DOCS/PROJEKT.md`) existieren, breche mit Hinweis ab: "Kein Session-Continuous Projekt erkannt. Mindestens CLAUDE.md oder PROJEKT.md wird benoetigt."

### Schritt 2: Alle Datenquellen einlesen

Lies die folgenden Quellen **in dieser Reihenfolge** (Prioritaet absteigend). Ueberspringe fehlende Quellen ohne Fehler.

#### Primaere Quellen (ALLE lesen)

1. **CLAUDE.md** — `$PWD/CLAUDE.md`
   - Extrahiere: Projekt-Zweck, Architektur, Workflow-Regeln, Kritische Regeln, Known Issues
   - Das ist die wichtigste Quelle fuer Architektur und Konventionen

2. **PROJEKT.md** — `$PWD/PROJEKT.md` ODER `$PWD/90_DOCS/PROJEKT.md`
   - Extrahiere: Executive Summary, Phasen-Status, Task-Uebersicht, Known Issues
   - Zeigt den aktuellen Projektstand

3. **Session Handoffs** — `$PWD/docs/handoffs/SESSION-HANDOFF-*.md` (letzte 5)
   - Extrahiere: Learnings, wiederkehrende Blocker, Empfehlungen
   - Sortiere nach Datum absteigend, nur die neuesten 5

4. **Auto-Memory** — Glob: `~/.claude/projects/*<pwd-basename>/memory/MEMORY.md`
   - Extrahiere: Persistente Patterns, User-Praeferenzen, bekannte Probleme
   - Pfad-Aufloesung: Claude kodiert absolute Pfade mit `-` als Trennzeichen (z.B. `C--Development-Projects-Claude-projekt-automation-hub`). Glob auf `*<pwd-basename>` matcht das Ende.

#### Sekundaere Quellen (lesen wenn vorhanden)

5. **Decision Log** — `$PWD/docs/DECISION-LOG.md`
   - Extrahiere: Die letzten 10 Entscheidungen (Kontext + Outcome)

6. **Abgeschlossene Tasks** — `$PWD/docs/tasks/TASK-*.md` (nur completed)
   - Extrahiere: Objective + Outcome (nicht die Details)
   - Nur Tasks mit `status: completed` im Frontmatter

#### Tertiäre Quellen (nur bei Existenz)

7. **Phasen-Zusammenfassungen** — `$PWD/docs/phases/Phase-*.md`
   - Extrahiere: Phasen-Name + Zusammenfassung (erste 3-5 Zeilen)

### Schritt 3: HOW-TO Dokument generieren

Schreibe das Dokument nach: `~/.claude/skills/setup-reference/references/HOW-TO-<PROJECT-NAME>.md`

**Hinweis:** Bewusste Integration mit `setup-reference` Skill — der `my-setup-guide` Agent liest HOW-TO Dateien aus diesem Verzeichnis. Dieses Cross-Skill-Sharing ist gewollt.

Verwende folgende Struktur:

```markdown
# HOW-TO: <Projekt-Name>

> **Generiert:** <YYYY-MM-DD> | **Quellen:** <Anzahl gelesener Quellen>/7

---

## Was ist dieses Projekt?

<2-3 Saetze aus CLAUDE.md Projekt-Zweck>

## Architektur

<Kernarchitektur aus CLAUDE.md — Ebenen, Datenfluss, zentrale Konzepte>

## Workflow & Konventionen

<Session-Workflow, Commit-Regeln, Naming-Conventions aus CLAUDE.md>
<Kritische Regeln die IMMER beachtet werden muessen>

## Aktueller Stand

<Aus PROJEKT.md: Welche Phase, was ist done, was steht an>
<Letzte 3-5 abgeschlossene Tasks als Bullet-Liste>

## Bekannte Herausforderungen

<Known Issues aus CLAUDE.md + PROJEKT.md>
<Wiederkehrende Blocker aus Handoffs>

## Learnings & Patterns

<Aus Memory + Handoffs: Was hat sich bewaehrt, was nicht>
<Persistente Patterns die session-uebergreifend gelten>

## Wichtige Entscheidungen

<Letzte 5-10 Entscheidungen aus Decision-Log, kompakt>

## Quick Reference

<Tabelle: Wichtigste Pfade, Commands, Skills fuer dieses Projekt>
```

### Schritt 4: Staleness-Tracking + PWD-Verweis

Nach erfolgreicher Generierung:

1. Pruefe ob in `$PWD/CLAUDE.md` bereits eine Zeile `HOW-TO zuletzt aktualisiert:` existiert
2. Falls ja: Aktualisiere Datum
3. Falls nein: Fuege in der **Dokument-Status** Zeile (am Ende von CLAUDE.md) hinzu:
   `**HOW-TO zuletzt aktualisiert:** YYYY-MM-DD`
4. Diese Zeile wird vom SessionStart Hook gelesen (Staleness > 7 Tage = Hint)

**Wichtig:** Die Tracking-Zeile gehoert in die bestehende Dokument-Status Zeile, NICHT als eigener Abschnitt. So bleibt sie bei `/claude-md-restructure` erhalten.

### Schritt 5: Zusammenfassung ausgeben

Zeige dem User:
- Welche Quellen gelesen wurden (mit Anzahl)
- Output-Pfad
- Dokumentgroesse (Zeilen/Zeichen)
- Naechster empfohlener Update-Zeitpunkt

## Qualitaetsregeln

- **Max 500 Zeilen** fuer das generierte Dokument
- **Keine Spekulation** — nur Fakten aus den gelesenen Quellen
- **Deduplizierung** — gleiche Info aus mehreren Quellen nur einmal
- **Deutsch** fuer Erklaerungen, **Englisch** fuer technische Begriffe
- **Keine Code-Bloecke kopieren** — nur beschreiben was der Code tut
- **Inverted Pyramid** — Wichtigstes zuerst, Details am Ende

## Abgrenzung

| Skill | Scope |
|-------|-------|
| `/generate-pwd-howto` | PWD-Daten → konzeptuelle Projekt-Dokumentation |
| `/refresh-reference` | Live-System → technisches Setup-Inventar |
| `/session-refresh` | Session-State → CLAUDE.md + PROJEKT.md Update |
