from __future__ import annotations

import re

from .models import BiteCard, BitePack, CourseRecord, QuizItem


def _sentences(text: str) -> list[str]:
    cleaned = re.sub(r"\s+", " ", text).strip()
    if not cleaned:
        return []
    parts = re.split(r"(?<=[.!?])\s+", cleaned)
    return [p.strip() for p in parts if len(p.strip()) > 40]


def _clip(text: str, max_len: int = 220) -> str:
    text = re.sub(r"\s+", " ", text).strip()
    if len(text) <= max_len:
        return text
    cut = text[: max_len - 1].rsplit(" ", 1)[0]
    return cut + "…"


def build_bite_pack(course: CourseRecord) -> BitePack:
    """Turn lecture overviews into original micro-lesson cards + simple quiz stems.

    This is a deterministic v1 (no LLM). Later stages can upgrade quality while
    keeping the same schema and attribution fields.
    """
    credit = (
        course.attribution.as_credit_line()
        if course.attribution
        else f"{course.professor}, {course.title} (Open course)"
    )
    bites: list[BiteCard] = []
    quizzes: list[QuizItem] = []
    order = 0

    if course.about:
        order += 1
        bites.append(
            BiteCard(
                id=f"{course.id}:about:1",
                course_id=course.id,
                lecture_id="about",
                order=order,
                kind="story",
                headline=f"Why {course.title}?",
                body=_clip(course.about, 280),
                attribution_line=credit,
                source_url=course.url,
                license_spdx=course.license.spdx,
            )
        )

    for lec in course.lectures:
        sents = _sentences(lec.overview)
        if not sents:
            order += 1
            bites.append(
                BiteCard(
                    id=f"{course.id}:{lec.id}:title",
                    course_id=course.id,
                    lecture_id=lec.id,
                    order=order,
                    kind="concept",
                    headline=lec.title,
                    body=f"Lecture {lec.index} in {course.title}. Open the source session for the full talk.",
                    attribution_line=credit,
                    source_url=lec.url,
                    license_spdx=course.license.spdx,
                )
            )
            continue

        order += 1
        bites.append(
            BiteCard(
                id=f"{course.id}:{lec.id}:hook",
                course_id=course.id,
                lecture_id=lec.id,
                order=order,
                kind="concept",
                headline=lec.title,
                body=_clip(sents[0], 240),
                attribution_line=credit,
                source_url=lec.url,
                license_spdx=course.license.spdx,
            )
        )

        if len(sents) > 1:
            order += 1
            bites.append(
                BiteCard(
                    id=f"{course.id}:{lec.id}:takeaway",
                    course_id=course.id,
                    lecture_id=lec.id,
                    order=order,
                    kind="takeaway",
                    headline="Keep this bit",
                    body=_clip(sents[1], 240),
                    attribution_line=credit,
                    source_url=lec.url,
                    license_spdx=course.license.spdx,
                )
            )

        # Lightweight comprehension check from the overview — not a dump of the lecture.
        focus = _clip(sents[0], 120)
        quizzes.append(
            QuizItem(
                id=f"{course.id}:{lec.id}:q1",
                course_id=course.id,
                lecture_id=lec.id,
                prompt=f"After “{lec.title}”, which best captures the lecture’s opening focus?",
                choices=[
                    focus,
                    "A purely biographical timeline with no philosophical claims.",
                    "A lab procedure unrelated to the course themes.",
                    "A summary of campus administrative policy.",
                ],
                answer_index=0,
                explanation="Grounded in the openly published lecture overview on Open Yale Courses.",
            )
        )

    return BitePack(course_id=course.id, bites=bites, quizzes=quizzes)
