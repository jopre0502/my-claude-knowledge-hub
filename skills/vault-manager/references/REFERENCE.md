# Vault Manager Skill - Technical Reference

**For setup & usage:** See `SETUP.md`

---

## Scripts Reference

### Document Discovery (CLI/MCP — ersetzt vault-find.sh)

**Method:** MCP Tool `obsidian_simple_search` oder CLI `obsidian.com search`

**Usage:**
```bash
# CLI
obsidian.com search query="document-name" format=json

# MCP Tool (in Claude Code)
obsidian_simple_search(query="document-name")
```

**Voraussetzung:** Obsidian App muss laufen (CLI kommuniziert via Named Pipe)
**Fallback:** Glob Tool mit Pattern `**/*name*.md` auf `$OBSIDIAN_VAULT`

> vault-find.sh wurde bei TASK-027 (CLI Migration, 2026-02-19) geloescht.

---

### Document Read (CLI/MCP — ersetzt vault-read.sh)

**Method:** MCP Tool `obsidian_get_file_contents` oder CLI `obsidian.com read`

**Usage:**
```bash
# CLI
obsidian.com read file="path/to/document.md"
obsidian.com properties file="path/to/document.md" format=yaml

# MCP Tool (in Claude Code)
obsidian_get_file_contents(filepath="path/to/document.md")
```

**Voraussetzung:** Obsidian App muss laufen
**Metadata:** `obsidian.com properties` liefert Frontmatter als YAML/TSV

> vault-read.sh wurde bei TASK-027 (CLI Migration, 2026-02-19) geloescht.

---

### vault-copy.sh <source-file> [target-folder]

**Purpose:** Copy or move existing files into the Obsidian Vault

**Location:** `~/.claude/skills/vault-manager/scripts/vault-copy.sh`

**Usage:**
```bash
vault-copy.sh /tmp/report.md
vault-copy.sh /tmp/report.md "03-Spaces/Gesundheit"
vault-copy.sh /tmp/report.md --move
vault-copy.sh /tmp/report.md --dry-run
vault-copy.sh /tmp/report.md --move --force
```

**Options:**
- `--move` - Remove source after copy (mv instead of cp)
- `--dry-run` - Show what would happen without writing
- `--force` - Overwrite existing file at target
- `--help` - Show usage

**Output:**
```
# Success
[INFO] Copy: /tmp/report.md → /path/to/vault/04 RESSOURCEN/report.md
/path/to/vault/04 RESSOURCEN/report.md

# Collision (without --force)
[ERROR] Target file already exists: /path/to/vault/04 RESSOURCEN/report.md (use --force to overwrite)

# Dry run
=== DRY RUN ===
Action:  Copy
Source:  /tmp/report.md
Target:  /path/to/vault/04 RESSOURCEN/report.md
=== No changes made ===
```

**Exit Codes:**
- `0` - Success
- `1` - Error (source not found, collision, vault not set)

**Default target folder:** `04 RESSOURCEN` (configurable via second argument)

---

### vault-base.sh <name>

**Purpose:** Execute Obsidian Base queries — parses `.base` files and runs filter logic via existing vault-manager scripts

**Location:** `~/.claude/skills/vault-manager/scripts/vault-base.sh`

**Usage:**
```bash
vault-base.sh <name>              # Execute base query, return matching documents
vault-base.sh --list              # List all .base files in vault
vault-base.sh --explain <name>    # Show parsed filters (human-readable)
```

**Supported Filters (MVP):**
- `property == "value"` — Frontmatter equality check
- `file.tags.containsAny("a","b")` — Tag search (delegates to vault-tags.sh)
- `file.hasTag("tag")` — Single tag search
- `!property.isEmpty()` — Property exists and non-empty
- `property <= today()` — Date comparison (<=, >=, <, >, ==)
- `file.ctime/mtime == today()` — Filesystem date match
- `file.ext == "md"` — File extension filter
- `and:`/`or:` conjunctions — Set intersection/union

**Unsupported (Phase 6+):** `.format()`, `formula.`, `list()`, `date()`, nested expressions, TaskNotes-specific filters

**Output:**
```
# Execute
Executing: 01 DASHBOARD/BASE_Bewerbungen_Dashboard.base

[INFO] Conjunction: and, 1 filter(s)
[INFO] Filter 1: 'fileClass == "Bewerbung"' → 325 matches
  04 RESSOURCEN/Bewerbungen/Company A.md
  04 RESSOURCEN/Bewerbungen/Company B.md
  ...

325 document(s) matched (conjunction: and, filters: 1, skipped: 0)

# Explain
Base: 01 DASHBOARD/BASE_Bewerbungen_Dashboard.base

  Global Filters:
    Conjunction: and
    [ok] fileClass == "Bewerbung"
  View 'Reminder' Filters:
    Conjunction: and
    [ok] !reminder.isEmpty()

# List
Base files in vault:

  01 DASHBOARD/BASE_Bewerbungen_Dashboard.base
  01 DASHBOARD/BASE_BIbliothek_Dashboard.base
  ...

19 base file(s) found
```

**Exit Codes:**
- `0` - Success
- `1` - Error (base not found, no filters, vault not set)

**Performance:**
- List: < 500ms
- Explain: < 500ms
- Execute: 5-30s depending on filter count and vault size (WSL2/NTFS I/O)

**Implementation Details:**
- Pure awk/bash YAML parser (no jq/yq dependency)
- Case-insensitive base file discovery (`find -iname`)
- Delegates tag filters to `vault-tags.sh`
- Set operations via temp files + `comm -12` (AND) / `sort -u` (OR)
- Gracefully skips unsupported filters with warning

---

## Frontmatter Schema

### Standard Format

```yaml
---
created: 2026-01-17
modified: 2026-01-17
tags: [ai, workflows, concepts]
status: active
type: note
---
```

### Field Details

| Field | Type | Required | Values | Example |
|-------|------|----------|--------|---------|
| `created` | Date | No | YYYY-MM-DD | 2026-01-17 |
| `modified` | Date | No | YYYY-MM-DD | 2026-01-17 |
| `tags` | Array | No | [tag1, tag2] | [ai, workflows] |
| `status` | String | No | draft, active, done, archived | active |
| `type` | String | No | note, project, meeting, session | note |

### Valid Examples

**Minimal (no frontmatter):**
```markdown
# Document Title

Content here...
```

**Basic frontmatter:**
```yaml
---
created: 2026-01-17
tags: [important]
---
```

**Full frontmatter:**
```yaml
---
created: 2026-01-17
modified: 2026-01-17
tags: [ai, workflows, research]
status: active
type: project
---
```

### Invalid Examples ❌

**Wrong date format:**
```yaml
created: January 17, 2026    # Wrong: should be 2026-01-17
```

**Missing brackets in array:**
```yaml
tags: ai, workflows          # Wrong: should be [ai, workflows]
```

**Unquoted special characters:**
```yaml
title: My: Special: Title    # Wrong: colons need quoting
title: "My: Special: Title"  # Correct
```

---

## Environment Variables

### OBSIDIAN_VAULT (Required)

**Purpose:** Root path to Obsidian Vault

**Format:** Absolute filesystem path

**Examples:**
```bash
# WSL2 Windows path
/mnt/c/Users/Jonas/Google Drive/01. Prechtel_Documents/250_Obsidian/PKM

# macOS
/Users/user/Documents/Obsidian Vault

# Linux
/home/user/vaults/my-vault
```

**Set via:**
```bash
# Environment
export OBSIDIAN_VAULT=/path/to/vault

# secret-run
echo "OBSIDIAN_VAULT=/path/to/vault" > ~/.config/secrets/env.d/vault.env
secret-run vault -- claude code

# Inline (development)
OBSIDIAN_VAULT=/path/to/vault claude code
```

**Default Behavior:** If not set, scripts use `.` (current directory)

---

## Error Codes & Messages

### Discovery Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `OBSIDIAN_VAULT not found` | Path doesn't exist | Set correct vault path |
| `Document not found` | Not in vault | Verify document exists, check spelling |
| `Multiple documents found` | Ambiguous name | Disambiguate with full name |

### Read Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `File not found` | Path invalid | Verify absolute path |
| `File not readable` | Permission denied | Check file permissions |
| `Frontmatter parse error` | Invalid YAML | Fix YAML syntax in document |

---

## Performance Characteristics

### Discovery

| Method | Time | Reliability |
|--------|------|-------------|
| Exact filename match | < 100ms | High |
| Partial match (fallback) | 500-1000ms | High |

**Optimization Tips:**
1. Use consistent naming (helps exact match)
2. Organize documents in folders (faster searching)

### Reading

| Operation | Time | Bottleneck |
|-----------|------|-----------|
| File read | < 100ms | I/O |
| Frontmatter parse | < 10ms | Regex |
| Total | < 110ms | File I/O |

---

## Limits & Constraints

| Limit | Value | Notes |
|-------|-------|-------|
| File size | ~1MB | Practical limit for parsing |
| Path length | 260 chars | Windows limitation |
| Vault size | 10,000+ notes | Fallback search 500ms-5s |
| Character encoding | UTF-8 | Assumption, other encodings may break |
| Frontmatter size | 10KB | Practical limit |

---

## Integration Points

### Script Integration

Discovery and read via CLI/MCP (Obsidian muss laufen):
```bash
# CLI (Terminal)
obsidian.com search query="document-name" format=json
obsidian.com read file="path/to/doc.md"

# MCP Tools (Claude Code, auto-triggered via vault-manager skill)
# Oder via commands: /vault-work, /vault-export
```

### Environment Setup

`OBSIDIAN_VAULT` is loaded automatically via SessionStart Hook:
```
~/.config/secrets/env.d/vault.env → CLAUDE_ENV_FILE → $OBSIDIAN_VAULT available
```

---

## Debugging Tips

### Enable verbose output

```bash
# Test discovery (Obsidian muss laufen)
obsidian.com search query="ai-workflows" format=json

# Test reading
obsidian.com read file="path/to/doc.md"
```

### Check environment

```bash
echo "Vault: $OBSIDIAN_VAULT"
ls "$OBSIDIAN_VAULT" | head -5
```

---

**Reference Version:** 2.0
**Status:** UC1-3 Complete (Bash-First)
**Last Updated:** 2026-02-11
