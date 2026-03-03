#!/usr/bin/env python3
"""
Identify Modular Disclosure candidates in CLAUDE.md.

Analyzes sections for outsourcing potential — resolved content, large tables,
and reference sections that should be moved to separate files.

NOTE: This script does NOT modify the file. It generates actionable
recommendations for manual or assisted outsourcing.

Usage:
    python3 apply_progressive_disclosure.py <claude-md-path>

Targets:
- Open Questions (resolved entries) -> move to Decision Log or archive
- Solved Challenges -> move to docs/ or remove
- Large tables (>8 rows) -> consider outsourcing to separate file
- Reference sections -> consider outsourcing to docs/

Exit codes:
    0 = No outsourcing needed
    1 = Error
    2 = Outsourcing candidates found (actionable)
"""

import sys
import re
from pathlib import Path
from typing import List, Tuple
from dataclasses import dataclass


@dataclass
class OutsourcingCandidate:
    """A section that could be outsourced to a separate file."""
    section_name: str
    line_start: int
    line_end: int
    size_bytes: int
    item_count: int
    category: str  # "resolved_questions", "solved_challenges", "large_table", "reference_section"
    recommendation: str


def find_resolved_questions(content: str) -> List[OutsourcingCandidate]:
    """Find Open Questions section with resolved items."""
    candidates = []

    oq_pattern = re.compile(
        r'(##\s*Open Questions.*?\n)(.*?)(?=\n##\s+[^#]|\n---\s*$|\Z)',
        re.DOTALL | re.IGNORECASE
    )

    match = oq_pattern.search(content)
    if not match:
        return candidates

    section_content = match.group(2)
    line_start = content[:match.start()].count('\n') + 1

    # Find resolved items
    resolved_pattern = re.compile(
        r'^(\s*[-*]\s*)~~(.+?)~~\s*$|^(\s*[-*]\s*)\[x\](.+?)$',
        re.MULTILINE | re.IGNORECASE
    )

    resolved_matches = list(resolved_pattern.finditer(section_content))

    if len(resolved_matches) >= 2:
        line_end = line_start + section_content.count('\n')
        size = sum(len(m.group(0).encode('utf-8')) for m in resolved_matches)

        candidates.append(OutsourcingCandidate(
            section_name="Open Questions (resolved)",
            line_start=line_start,
            line_end=line_end,
            size_bytes=size,
            item_count=len(resolved_matches),
            category="resolved_questions",
            recommendation=(
                f"{len(resolved_matches)} resolved Questions gefunden. "
                f"Empfehlung: Nach docs/DECISION-LOG.md verschieben oder entfernen."
            )
        ))

    return candidates


def find_solved_challenges(content: str) -> List[OutsourcingCandidate]:
    """Find solved challenge sections."""
    candidates = []

    challenge_pattern = re.compile(
        r'(###\s*Challenge\s*\d+:.*?)\n(.*?)(?=\n###\s+|\n##\s+|\Z)',
        re.DOTALL
    )

    for match in challenge_pattern.finditer(content):
        header = match.group(1)
        body = match.group(2)

        if 'geloest' in header.lower() or 'solved' in header.lower() or 'Problem geloest' in body:
            line_start = content[:match.start()].count('\n') + 1
            line_end = line_start + (header + body).count('\n')
            size = len((header + body).encode('utf-8'))

            candidates.append(OutsourcingCandidate(
                section_name=header.strip()[:60],
                line_start=line_start,
                line_end=line_end,
                size_bytes=size,
                item_count=1,
                category="solved_challenges",
                recommendation=(
                    f"Geloeste Challenge ({size:,} Bytes). "
                    f"Empfehlung: Entfernen oder nach docs/ auslagern."
                )
            ))

    return candidates


def find_large_tables(content: str, max_rows: int = 8) -> List[OutsourcingCandidate]:
    """Find tables with many rows that could be outsourced."""
    candidates = []

    table_pattern = re.compile(
        r'(\|[^\n]+\|\n\|[-:\s|]+\|\n)((?:\|[^\n]+\|\n){' + str(max_rows) + r',})',
        re.MULTILINE
    )

    for match in table_pattern.finditer(content):
        table_header = match.group(1)
        table_rows = match.group(2)
        row_count = table_rows.strip().count('\n') + 1

        # Skip main task table
        if 'UUID' in table_header and 'Dependencies' in table_header:
            continue

        line_start = content[:match.start()].count('\n') + 1
        line_end = line_start + (table_header + table_rows).count('\n')
        size = len((table_header + table_rows).encode('utf-8'))

        candidates.append(OutsourcingCandidate(
            section_name=f"Tabelle ({row_count} Zeilen)",
            line_start=line_start,
            line_end=line_end,
            size_bytes=size,
            item_count=row_count,
            category="large_table",
            recommendation=(
                f"Grosse Tabelle mit {row_count} Zeilen ({size:,} Bytes). "
                f"Empfehlung: In separate Datei auslagern und per Link referenzieren."
            )
        ))

    return candidates


def find_reference_sections(content: str) -> List[OutsourcingCandidate]:
    """Find reference sections that are rarely needed inline."""
    candidates = []

    ref_candidates = [
        (r'##\s*Referenzen\s*(?:&|und)?\s*Externe\s*Ressourcen', 'Referenzen'),
        (r'##\s*Haeufige\s*Development\s*Tasks', 'Development Tasks'),
    ]

    for pattern, name in ref_candidates:
        section_match = re.search(
            f'({pattern}.*?\\n)(.*?)(?=\\n##\\s+[^#]|\\n---\\s*$|\\Z)',
            content,
            re.DOTALL | re.IGNORECASE
        )

        if not section_match:
            continue

        body = section_match.group(2)
        size = len(body.encode('utf-8'))

        if size < 500:
            continue

        line_start = content[:section_match.start()].count('\n') + 1
        line_end = line_start + (section_match.group(0)).count('\n')

        candidates.append(OutsourcingCandidate(
            section_name=name,
            line_start=line_start,
            line_end=line_end,
            size_bytes=size,
            item_count=1,
            category="reference_section",
            recommendation=(
                f"Referenz-Sektion '{name}' ({size:,} Bytes). "
                f"Empfehlung: In separate Datei docs/{name.lower().replace(' ', '-')}.md auslagern."
            )
        ))

    return candidates


def analyze_modular_disclosure(file_path: str) -> List[OutsourcingCandidate]:
    """Main analysis function — find all outsourcing candidates."""
    path = Path(file_path)

    if not path.exists():
        print(f"Error: File not found: {file_path}")
        return []

    content = path.read_text(encoding='utf-8')

    candidates = []
    candidates.extend(find_resolved_questions(content))
    candidates.extend(find_solved_challenges(content))
    candidates.extend(find_large_tables(content))
    candidates.extend(find_reference_sections(content))

    return candidates


def print_report(file_path: str, candidates: List[OutsourcingCandidate]) -> None:
    """Print formatted analysis report."""
    print(f"Modular Disclosure Analyse: {file_path}")
    print("=" * 60)

    if not candidates:
        print("Keine Auslagerungs-Kandidaten gefunden.")
        print("Dokument ist bereits gut strukturiert.")
        return

    total_bytes = sum(c.size_bytes for c in candidates)
    print(f"Gefunden: {len(candidates)} Kandidaten ({total_bytes:,} Bytes Einsparpotential)")
    print("-" * 60)

    for i, c in enumerate(candidates, 1):
        print(f"\n{i}. [{c.category}] {c.section_name}")
        print(f"   Zeilen {c.line_start}-{c.line_end} | {c.size_bytes:,} Bytes | {c.item_count} Items")
        print(f"   -> {c.recommendation}")

    print("\n" + "=" * 60)
    print(f"Gesamt-Einsparpotential: {total_bytes:,} Bytes")
    print("Hinweis: Dieses Script aendert keine Dateien. Empfehlungen manuell umsetzen.")


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 apply_progressive_disclosure.py <claude-md-path>")
        print("\nAnalysiert CLAUDE.md auf Auslagerungs-Kandidaten (Modular Disclosure).")
        print("Aendert keine Dateien — gibt nur Empfehlungen aus.")
        print("\nExamples:")
        print("  python3 apply_progressive_disclosure.py CLAUDE.md")
        sys.exit(1)

    file_path = sys.argv[1]
    candidates = analyze_modular_disclosure(file_path)
    print_report(file_path, candidates)

    # Exit code: 2 if candidates found, 0 if clean
    sys.exit(2 if candidates else 0)


if __name__ == "__main__":
    main()
