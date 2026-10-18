import sys
from pathlib import Path

# Make `main` importable when pytest is run from anywhere.
sys.path.insert(
    0, str(Path(__file__).resolve().parents[3] / "src" / "api" / "core_service")
)
