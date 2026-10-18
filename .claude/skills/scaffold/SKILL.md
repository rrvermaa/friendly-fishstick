---
name: scaffold
description: Build the standard project structure in the current repo - folders, a runnable Vite + React frontend, a runnable FastAPI backend, GitHub Actions workflows, Docker files and pre-push check scripts. Use when the user runs /scaffold or asks to set up the project structure.
---

# Scaffold the project

Run from anywhere inside the repo (it finds the git root itself):

```bash
python .claude/skills/scaffold/scripts/scaffold.py --dry-run   # preview
python .claude/skills/scaffold/scripts/scaffold.py             # create
```

## Steps

1. Run with `--dry-run` and show the user the list.
2. Run it for real.
3. Report how many files were created and tell the user the run commands below.
   Do not commit unless asked.

It never overwrites anything, so re-running is safe; existing files and folders are skipped.
It installs nothing.

## What it creates

- **Folders**: `src/{api/core_service,ui,agents}`, `tests/...`, `docs`, `configs`, `scripts`,
  `deployments`, `.github/workflows`, `.githooks`. Python packages get `__init__.py`, empty
  folders get `.gitkeep`. Appends `node_modules/` and `dist/` to `.gitignore`.
- **Backend** `src/api/core_service/`: `main.py` (FastAPI: `/`, `/api/v1/health`),
  `requirements.txt` (runtime), `requirements-dev.txt` (+ pytest, httpx, ruff, mypy),
  `pyproject.toml` (ruff + mypy), `.env.example`, plus `tests/api/core_service/test_health.py`.
  Run: `pip install -r requirements-dev.txt`, `uvicorn main:app --reload` (port 8000, `/docs`).
- **Frontend** `src/ui/`: Vite + React template page, `src/assets/logo.svg`, ESLint, Prettier,
  `jsconfig.json` (type-check), npm scripts `dev build format:check lint type-check dep-check`.
  Run: `npm install`, `npm run dev` (port 5173; `/api` is proxied to the backend).
- **Workflows** `.github/workflows/`: `ci.yml` (backend ruff/mypy/pytest + frontend
  prettier/eslint/tsc/build) and `backend-docker.yml` (push image to Docker Hub as
  `<DOCKERHUB_USERNAME>/<repo>-backend`; needs secrets `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`).
  CI uses `npm ci`, so commit `src/ui/package-lock.json` (created by the first `npm install`).
- **Docker** `deployments/`: `Dockerfile` (backend), `docker-compose.yml` (postgres + backend),
  `README.md`; `.dockerignore` at the root.
- **Scripts** `scripts/`: `check-before-push.sh` (auto-fix then validate; a part is skipped if its
  folder is missing), `check-conventions.sh` (snake_case Python names, `test_*` files/functions),
  `setup-git-hooks.sh`; `.githooks/pre-push` calls the check script.
  Enable the hook with `bash scripts/setup-git-hooks.sh`.

Everything is generic: the repo folder name replaces `__PROJECT_NAME__` / `__PACKAGE_NAME__` in
the templates. Paths can be overridden for the scripts with `FRONTEND_DIR`, `BACKEND_DIR`,
`BACKEND_TESTS_DIR` env vars.

## Changing the layout

- Starter files are plain files in `templates/`, mirrored 1:1 into the repo root. Add, edit or
  remove files there; no script change needed.
- Folder lists (`PYTHON_PACKAGES`, `PLAIN_DIRS`) are at the top of `scripts/scaffold.py`.
- Layout notes: [references/structure.md](references/structure.md).
- `scripts/legacy_module_generator.py` is an old per-module generator (FastAPI module, UI feature)
  from another project; it needs files that don't exist here and is not used by `/scaffold`.

## Verified

The scaffold output was run end to end in a clean repo: `scripts/check-before-push.sh` passes
(prettier, eslint, tsc, vite build, ruff, mypy, pytest). The Dockerfile build and the GitHub
workflows themselves have not been run (compose and workflow YAML parse fine).
