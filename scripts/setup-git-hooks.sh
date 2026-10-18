#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

git config core.hooksPath .githooks
chmod +x .githooks/pre-push scripts/check-before-push.sh scripts/check-conventions.sh

echo "Git hooks configured. pre-push checks are now enforced locally."
