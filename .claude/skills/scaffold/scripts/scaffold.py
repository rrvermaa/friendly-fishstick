#!/usr/bin/env python3
"""Create the standard folder structure and starter files in the current repo.

    scaffold.py [--dry-run]

Starter files come from ../templates, mirrored 1:1 into the repo root. __PROJECT_NAME__ is
replaced with the repo folder name and __PACKAGE_NAME__ with its lowercase-kebab form.

Safe to re-run: existing files and folders are left alone, nothing is overwritten.
Standard library only.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
from pathlib import Path

TEMPLATES = Path(__file__).resolve().parent.parent / "templates"

# Python packages get an __init__.py, the rest get a .gitkeep so git tracks them.
PYTHON_PACKAGES = [
    "src/api/core_service",
    "src/api/core_service/api",
    "src/api/core_service/api/v1",
    "src/api/core_service/core",
    "src/api/core_service/db",
    "src/api/core_service/modules",
    "src/api/core_service/utils",
    "src/agents",
    "tests",
    "tests/agents",
    "tests/api",
    "tests/api/core_service",
    "tests/db",
]

PLAIN_DIRS = [
    "configs",
    "docs/architecture",
    "src/api/core_service/alembic/versions",
    "src/ui/public",
    "src/ui/src/api/services",
    "src/ui/src/components",
    "src/ui/src/hooks",
    "src/ui/src/pages",
]

GITIGNORE_LINES = ["node_modules/", "dist/"]
EXECUTABLE = {".sh"}
EXECUTABLE_NAMES = {"pre-push"}


def repo_root() -> Path:
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True
        )
        return Path(out.stdout.strip())
    except (OSError, subprocess.CalledProcessError):
        return Path.cwd()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="show what would be created, write nothing")
    args = parser.parse_args()

    root = repo_root()
    project = root.name
    package = re.sub(r"[^a-z0-9]+", "-", project.lower()).strip("-") or "app"
    print(f"Scaffolding in {root}")
    created = skipped = 0

    def make(path: Path, content: str = "", executable: bool = False) -> None:
        nonlocal created, skipped
        if path.exists():
            skipped += 1
            return
        print(f"  create  {path.relative_to(root).as_posix()}")
        created += 1
        if not args.dry_run:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8", newline="\n")
            if executable:
                path.chmod(path.stat().st_mode | 0o111)

    for rel in PYTHON_PACKAGES:
        make(root / rel / "__init__.py")
    for rel in PLAIN_DIRS:
        make(root / rel / ".gitkeep")
    make(root / "README.md", f"# {project}\n")

    for source in sorted(p for p in TEMPLATES.rglob("*") if p.is_file()):
        rel = source.relative_to(TEMPLATES)
        content = source.read_text(encoding="utf-8")
        content = content.replace("__PROJECT_NAME__", project).replace("__PACKAGE_NAME__", package)
        executable = source.suffix in EXECUTABLE or source.name in EXECUTABLE_NAMES
        make(root / rel, content, executable)

    gitignore = root / ".gitignore"
    existing = gitignore.read_text(encoding="utf-8").splitlines() if gitignore.exists() else []
    missing = [line for line in GITIGNORE_LINES if line not in existing]
    if missing:
        print(f"  append  .gitignore  ({', '.join(missing)})")
        if not args.dry_run:
            with gitignore.open("a", encoding="utf-8", newline="\n") as f:
                f.write("\n# frontend\n" + "\n".join(missing) + "\n")

    verb = "would create" if args.dry_run else "created"
    print(f"\nDone: {verb} {created} file(s), {skipped} already existed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
