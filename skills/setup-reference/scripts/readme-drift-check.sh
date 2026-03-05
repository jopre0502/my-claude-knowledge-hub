#!/usr/bin/env bash
# readme-drift-check.sh — Vergleicht README.md "At a glance" gegen tatsaechlichen Inhalt
# Verwendung: bash readme-drift-check.sh
# Exit-Code: 0 = kein Drift, 1 = Drift erkannt, 2 = README nicht parsebar

set -uo pipefail

HUB_DIR="$HOME/.claude"
README="$HUB_DIR/README.md"
SETTINGS="$HUB_DIR/settings.json"

# --- Scan: Zaehle aktive Komponenten (keine _archived, keine Pipes in Loops) ---
# Hinweis: kein set -e wegen (( )) Arithmetic (0++ = falsy → exit)

scan_skills=0
if [[ -d "$HUB_DIR/skills" ]]; then
  for d in "$HUB_DIR/skills"/*/; do
    [[ -d "$d" ]] || continue
    name="${d%/}"
    name="${name##*/}"
    # Skip archived (underscore prefix)
    [[ "$name" == _* ]] && continue
    scan_skills=$((scan_skills + 1))
  done
fi

scan_agents=0
if [[ -d "$HUB_DIR/agents" ]]; then
  for f in "$HUB_DIR/agents"/*.md; do
    [[ -f "$f" ]] || continue
    scan_agents=$((scan_agents + 1))
  done
fi

scan_commands=0
if [[ -d "$HUB_DIR/commands" ]]; then
  for f in "$HUB_DIR/commands"/*.md; do
    [[ -f "$f" ]] || continue
    scan_commands=$((scan_commands + 1))
  done
fi

scan_hooks=0
if [[ -d "$HUB_DIR/hooks" ]]; then
  for f in "$HUB_DIR/hooks"/*.sh; do
    [[ -f "$f" ]] || continue
    scan_hooks=$((scan_hooks + 1))
  done
fi

scan_plugins=0
if [[ -f "$SETTINGS" ]] && command -v jq &>/dev/null; then
  scan_plugins=$(jq '[.enabledPlugins // {} | to_entries[] | select(.value == true)] | length' "$SETTINGS" 2>/dev/null | tr -d '\r') || scan_plugins=0
fi

# --- Parse: Extrahiere Zahlen aus README "At a glance" Tabelle ---

if [[ ! -f "$README" ]]; then
  echo "SKIP: README.md nicht gefunden ($README)"
  exit 2
fi

readme_content=$(<"$README")

# Parse "| **Skills** | 18 | examples |" — extract count from second column
parse_readme_count() {
  local component="$1"
  local count=""
  while IFS= read -r line; do
    line="${line%$'\r'}"
    if [[ "$line" == *"**${component}**"* ]]; then
      # Skip past the component name to get the count column
      local after="${line#*"**${component}**"}"
      # after = " | 18 | session-refresh, ..."
      after="${after#*| }"
      # after = "18 | session-refresh, ..."
      count="${after%%|*}"
      # count = "18 "
      count="${count//[!0-9]/}"
      break
    fi
  done <<< "$readme_content"
  echo "${count:-PARSE_ERROR}"
}

readme_skills=$(parse_readme_count "Skills")
readme_agents=$(parse_readme_count "Agents")
readme_commands=$(parse_readme_count "Commands")
readme_hooks=$(parse_readme_count "Hooks")
readme_plugins=$(parse_readme_count "Plugins")

# --- Check parse success ---

parse_ok=true
for val in "$readme_skills" "$readme_agents" "$readme_commands" "$readme_hooks" "$readme_plugins"; do
  if [[ "$val" == "PARSE_ERROR" ]]; then
    parse_ok=false
    break
  fi
done

if ! $parse_ok; then
  echo "SKIP: README.md 'At a glance' Tabelle nicht parsebar"
  echo "  Skills=$readme_skills Agents=$readme_agents Commands=$readme_commands Hooks=$readme_hooks Plugins=$readme_plugins"
  exit 2
fi

# --- Diff: Vergleiche und berichte ---

drift=false
drift_report=""

check_drift() {
  local name="$1" scan="$2" readme="$3"
  if [[ "$scan" -ne "$readme" ]]; then
    local diff=$((scan - readme))
    local sign="+"
    ((diff < 0)) && sign=""
    drift_report+="  ${name}: README sagt ${readme}, tatsaechlich ${scan} (${sign}${diff})"$'\n'
    drift=true
  else
    drift_report+="  ${name}: OK (${scan})"$'\n'
  fi
}

check_drift "Skills" "$scan_skills" "$readme_skills"
check_drift "Agents" "$scan_agents" "$readme_agents"
check_drift "Commands" "$scan_commands" "$readme_commands"
check_drift "Hooks" "$scan_hooks" "$readme_hooks"
check_drift "Plugins" "$scan_plugins" "$readme_plugins"

echo "README Drift-Check:"
echo "$drift_report"

if $drift; then
  echo "Empfehlung: README.md 'At a glance' Tabelle aktualisieren."
  exit 1
else
  echo "Alles synchron."
  exit 0
fi
