#!/usr/bin/env bash
# Naming conventions: snake_case Python folders/files, test_*.py files, test_* functions.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BACKEND_DIR="${BACKEND_DIR:-src/api/core_service}"
BACKEND_TESTS_DIR="${BACKEND_TESTS_DIR:-tests/api/core_service}"

python_dirs=("$BACKEND_DIR" "$BACKEND_TESTS_DIR")

errors=0

is_snake_case() {
  [[ "$1" =~ ^[a-z][a-z0-9_]*$ ]]
}

# alembic names migrations <revision>_<slug>
is_alembic_revision_name() {
  [[ "$1" =~ ^[0-9a-f]+_[a-z][a-z0-9_]*$ ]]
}

PRUNE=(\( -name ".*" -o -name "__pycache__" -o -name "node_modules" -o -name "media" \) -prune)

echo "Checking Python folder naming (snake_case)..."
for target in "${python_dirs[@]}"; do
  [[ -d "$target" ]] || continue

  while IFS= read -r dir_path; do
    if ! is_snake_case "$(basename "$dir_path")"; then
      echo "[convention] Directory must be snake_case: $dir_path"
      errors=1
    fi
  done < <(find "$target" "${PRUNE[@]}" -o -type d -print)
done

echo "Checking Python file naming (snake_case)..."
for target in "${python_dirs[@]}"; do
  [[ -d "$target" ]] || continue

  while IFS= read -r file_path; do
    file_name="$(basename "$file_path")"

    if [[ "$file_name" == "__init__.py" ]] || [[ "$file_name" == "conftest.py" ]]; then
      continue
    fi

    stem="${file_name%.py}"

    if [[ "$file_path" == "$BACKEND_DIR"/alembic/versions/* ]] && is_alembic_revision_name "$stem"; then
      continue
    fi

    if ! is_snake_case "$stem"; then
      echo "[convention] Python file must be snake_case: $file_path"
      errors=1
    fi

    if [[ "$file_path" == "$BACKEND_TESTS_DIR"/* ]] && [[ "$file_name" != test_*.py ]]; then
      echo "[convention] Test file must start with test_: $file_path"
      errors=1
    fi
  done < <(find "$target" "${PRUNE[@]}" -o -type f -name "*.py" -print)
done

echo "Checking test function naming (test_...)..."
if [[ -n "${PYTHON_INTERPRETER:-}" ]] && [[ -x "${PYTHON_INTERPRETER}" ]]; then
  PYTHON="$PYTHON_INTERPRETER"
elif command -v python3 >/dev/null 2>&1; then
  PYTHON="python3"
elif command -v python >/dev/null 2>&1; then
  PYTHON="python"
else
  echo "Python is not available to validate test function names."
  exit 1
fi

BACKEND_TESTS_DIR="$BACKEND_TESTS_DIR" "$PYTHON" - <<'PY'
import ast
import os
import sys
from pathlib import Path

root = Path(os.environ["BACKEND_TESTS_DIR"])
if not root.exists():
    sys.exit(0)

errors: list[str] = []
for file_path in root.rglob("*.py"):
    if file_path.name in {"__init__.py", "conftest.py"}:
        continue

    tree = ast.parse(file_path.read_text(encoding="utf-8"), filename=str(file_path))
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name.startswith("test"):
            if not node.name.startswith("test_"):
                errors.append(
                    f"[convention] Test function must use test_ prefix: "
                    f"{file_path}:{node.lineno} ({node.name})"
                )

if errors:
    print("\n".join(errors))
    sys.exit(1)
PY

if [[ $errors -ne 0 ]]; then
  echo "Convention checks failed."
  exit 1
fi

echo "Convention checks passed."
