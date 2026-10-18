#!/usr/bin/env bash
# Auto-fix, then validate frontend and backend. Run by .githooks/pre-push.
# A part is skipped when its folder does not exist, so this works for backend-only or UI-only repos.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FRONTEND_DIR="${FRONTEND_DIR:-src/ui}"
BACKEND_DIR="${BACKEND_DIR:-src/api/core_service}"
BACKEND_TESTS_DIR="${BACKEND_TESTS_DIR:-tests/api/core_service}"

HAS_FRONTEND=false
HAS_BACKEND=false
[[ -f "$FRONTEND_DIR/package.json" ]] && HAS_FRONTEND=true
[[ -d "$BACKEND_DIR" ]] && HAS_BACKEND=true

section() {
  echo ""
  echo "========================================"
  echo "$1"
  echo "========================================"
}

# =========================================================
# Python interpreter
# =========================================================

if [[ -x "$ROOT_DIR/.venv/bin/python" ]]; then
  PYTHON="$ROOT_DIR/.venv/bin/python"
elif [[ -x "$ROOT_DIR/.venv/Scripts/python.exe" ]]; then
  PYTHON="$ROOT_DIR/.venv/Scripts/python.exe"
elif command -v python3 >/dev/null 2>&1; then
  PYTHON="python3"
elif command -v python >/dev/null 2>&1; then
  PYTHON="python"
else
  echo "Python is not available. Install Python or create .venv first."
  exit 1
fi

# =========================================================
# Naming convention checks
# =========================================================

section "Running naming convention checks..."
PYTHON_INTERPRETER="$PYTHON" bash "$ROOT_DIR/scripts/check-conventions.sh"

# =========================================================
# Frontend
# =========================================================

if $HAS_FRONTEND; then
  pushd "$ROOT_DIR/$FRONTEND_DIR" >/dev/null

  section "Preparing frontend dependencies..."
  if [[ ! -x "node_modules/.bin/eslint" ]] || [[ ! -x "node_modules/.bin/prettier" ]]; then
    if [[ -f "package-lock.json" ]]; then
      npm ci
    else
      npm install
    fi
  else
    echo "Frontend dependencies are ready. Skipping install."
  fi

  section "Auto-fixing frontend..."
  npx --no-install prettier --write .
  npm run lint -- --fix

  section "Validating frontend..."
  echo "[1/5] Prettier";   npm run format:check
  echo "[2/5] ESLint";     npm run lint
  echo "[3/5] Type-check"; npm run type-check
  echo "[4/5] Build";      npm run build
  echo "[5/5] Dependency tree"; npm run dep-check

  popd >/dev/null
else
  echo "No $FRONTEND_DIR/package.json - skipping frontend checks."
fi

# =========================================================
# Backend
# =========================================================

if $HAS_BACKEND; then
  PY_TARGETS=("$BACKEND_DIR")
  [[ -d "$BACKEND_TESTS_DIR" ]] && PY_TARGETS+=("$BACKEND_TESTS_DIR")

  section "Auto-fixing Python..."
  "$PYTHON" -m ruff format "${PY_TARGETS[@]}"
  "$PYTHON" -m ruff check --fix "${PY_TARGETS[@]}"

  section "Validating backend..."
  echo "[1/5] Ruff format";  "$PYTHON" -m ruff format --check "${PY_TARGETS[@]}"
  echo "[2/5] Ruff lint";    "$PYTHON" -m ruff check "${PY_TARGETS[@]}"
  echo "[3/5] mypy";         "$PYTHON" -m mypy --config-file "$BACKEND_DIR/pyproject.toml" "$BACKEND_DIR"
  echo "[4/5] pip check";    "$PYTHON" -m pip check
  echo "[5/5] pytest"
  if [[ -d "$BACKEND_TESTS_DIR" ]]; then
    PYTHONPATH="$ROOT_DIR/$BACKEND_DIR" "$PYTHON" -m pytest -q "$BACKEND_TESTS_DIR"
  else
    echo "No $BACKEND_TESTS_DIR - skipping tests."
  fi
else
  echo "No $BACKEND_DIR - skipping backend checks."
fi

section "ALL PRE-PUSH CHECKS PASSED - ready to push."
