from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

from .models import BitePack, CourseRecord


def course_bundle(course: CourseRecord, pack: BitePack) -> dict:
    """Single drop-in file the iOS app can load from Resources/Courses/."""
    attr = None
    if course.attribution:
        attr = {
            "faculty": course.attribution.faculty,
            "course_title": course.attribution.course_title,
            "institution": course.attribution.institution,
            "project": course.attribution.project,
            "source_url": course.attribution.source_url,
            "credit_line": course.attribution.as_credit_line(),
        }

    return {
        "schema_version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "course": {
            "id": course.id,
            "source": course.source,
            "title": course.title,
            "professor": course.professor,
            "department": course.department,
            "number": course.number,
            "term": course.term,
            "about": course.about,
            "url": course.url,
            "path": course.path,
            "accent_label": f"{course.source.title()} · Open Course",
            "license": course.license.model_dump(),
            "attribution": attr,
        },
        "bites": [b.model_dump(mode="json") for b in pack.bites],
        "quizzes": [q.model_dump(mode="json") for q in pack.quizzes],
    }


def write_bundle(course: CourseRecord, pack: BitePack, courses_dir: Path) -> Path:
    courses_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{course.id.replace(':', '_')}.course.json"
    path = courses_dir / filename
    payload = course_bundle(course, pack)
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    # Keep a simple manifest of every *.course.json in the folder
    manifest_path = courses_dir / "manifest.json"
    ids = sorted(
        p.stem.replace(".course", "")
        for p in courses_dir.glob("*.course.json")
    )
    # ids from filenames like yale_phil-176.course.json → yale_phil-176; store course ids from files
    course_ids: list[str] = []
    for p in sorted(courses_dir.glob("*.course.json")):
        try:
            data = json.loads(p.read_text(encoding="utf-8"))
            course_ids.append(data["course"]["id"])
        except (KeyError, json.JSONDecodeError):
            continue
    manifest_path.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "updated_at": datetime.now(timezone.utc).isoformat(),
                "courses": course_ids,
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    return path
