#!/usr/bin/env python3
"""Domain Name Normalization Script

修正 atdd-hub 中 task JSON 的 domain 命名不一致問題。

Usage:
    python3 domain-normalize.py [--dry-run] [atdd-hub-path]
"""

import json
import sys
import os
from pathlib import Path

# Normalization mapping: old_name → new_name
DOMAIN_MAP = {
    "ErpPeriod": "Tools::ErpPeriod",
    "DigiwinErp": "Tools::DigiwinErp",
    "Tool::Receipt": "Receipt",
    "ProjectManagement": "Project::Management",
    "ProjectManagement::Project": "Project::Management",
    "infrastructure": "InfrastructureAutomation",
}


def normalize_task(filepath, dry_run):
    """Normalize domain name in a single task JSON. Returns change info or None."""
    with open(filepath, "r") as f:
        task = json.load(f)

    domain = task.get("domain", "")
    if not domain:
        return None

    changes = {}

    # Case 1: Comma-separated multi-domain
    if "," in domain:
        parts = [p.strip() for p in domain.split(",")]
        primary = parts[0]
        secondary = parts[1:]

        # Normalize primary if needed
        if primary in DOMAIN_MAP:
            primary = DOMAIN_MAP[primary]

        changes["old_domain"] = domain
        changes["new_domain"] = primary
        changes["added_related"] = secondary

        if not dry_run:
            task["domain"] = primary
            context = task.setdefault("context", {})
            related = context.setdefault("relatedDomains", [])
            for s in secondary:
                if s and s not in related:
                    related.append(s)
            with open(filepath, "w") as f:
                json.dump(task, f, ensure_ascii=False, indent=2)
                f.write("\n")

        return changes

    # Case 2: Simple rename
    if domain in DOMAIN_MAP:
        new_domain = DOMAIN_MAP[domain]
        changes["old_domain"] = domain
        changes["new_domain"] = new_domain

        if not dry_run:
            task["domain"] = new_domain
            with open(filepath, "w") as f:
                json.dump(task, f, ensure_ascii=False, indent=2)
                f.write("\n")

        return changes

    return None


def main():
    dry_run = "--dry-run" in sys.argv
    args = [a for a in sys.argv[1:] if a != "--dry-run"]
    hub_path = Path(args[0]) if args else Path.home() / "atdd-hub"

    tasks_dir = hub_path / "tasks"
    if not tasks_dir.exists():
        print(f"Error: {tasks_dir} not found")
        sys.exit(1)

    print(f"=== Domain Name Normalization ===")
    print(f"Hub path: {hub_path}")
    print(f"Dry run: {dry_run}")
    print(f"")
    print(f"Mapping:")
    for old, new in DOMAIN_MAP.items():
        print(f"  {old} → {new}")
    print(f"  (comma-separated) → split into domain + relatedDomains")
    print(f"")

    modified = 0
    errors = 0

    for json_file in sorted(tasks_dir.rglob("*.json")):
        try:
            result = normalize_task(json_file, dry_run)
            if result:
                modified += 1
                rel_path = json_file.relative_to(hub_path)
                old = result["old_domain"]
                new = result["new_domain"]
                extra = ""
                if "added_related" in result:
                    extra = f" (+relatedDomains: {result['added_related']})"
                prefix = "[DRY-RUN]" if dry_run else "[FIXED]"
                print(f"  {prefix} {rel_path}")
                print(f"    '{old}' → '{new}'{extra}")
        except Exception as e:
            errors += 1
            print(f"  [ERROR] {json_file}: {e}")

    print(f"")
    print(f"=== Summary ===")
    print(f"Modified: {modified}")
    print(f"Errors: {errors}")
    print(f"Dry run: {dry_run}")

    if dry_run and modified > 0:
        print(f"\nRun without --dry-run to apply changes.")


if __name__ == "__main__":
    main()
