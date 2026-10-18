# Core Service (FastAPI)

```bash
python -m venv .venv
.venv/Scripts/activate              # macOS/Linux: source .venv/bin/activate
pip install -r requirements-dev.txt # runtime deps only: requirements.txt
uvicorn main:app --reload           # http://127.0.0.1:8000  (docs at /docs)
```

Checks (also run by the pre-push hook): `ruff format`, `ruff check`, `mypy`, `pytest`.
