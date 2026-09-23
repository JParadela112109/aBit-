from __future__ import annotations

import json
from pathlib import Path
from typing import Any

EDITORIAL_DIR = Path(__file__).resolve().parents[1] / "data" / "editorial"


def editorial_path_for(course_id: str) -> Path:
    return EDITORIAL_DIR / f"{course_id.replace(':', '_')}.json"


def load_editorial(course_id: str) -> dict[str, Any] | None:
    path = editorial_path_for(course_id)
    if not path.exists():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def lecture_override(editorial: dict[str, Any], lecture_index: int) -> dict[str, Any] | None:
    lectures = editorial.get("lectures") or {}
    return lectures.get(str(lecture_index)) or lectures.get(lecture_index)
