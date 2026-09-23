from __future__ import annotations

import hashlib
import re

from .models import BiteCard, BitePack, CourseRecord, QuizItem

GENERIC_DISTRACTORS = [
    "A claim that the lecture never raises.",
    "A purely historical anecdote with no conceptual stakes.",
    "An administrative policy unrelated to the course themes.",
    "A lab method from an unrelated science course.",
    "A biographical timeline that avoids the central question.",
]


def _sentences(text: str) -> list[str]:
    cleaned = re.sub(r"\s+", " ", text).strip()
    if not cleaned:
        return []
    parts = re.split(r"(?<=[.!?])\s+", cleaned)
    return [p.strip() for p in parts if len(p.strip()) > 35]


def _clip(text: str, max_len: int = 220) -> str:
    text = re.sub(r"\s+", " ", text).strip()
    if len(text) <= max_len:
        return text
    cut = text[: max_len - 1].rsplit(" ", 1)[0]
    return cut + "…"


def _title_case_term(phrase: str) -> str:
    words = re.findall(r"[A-Za-z][A-Za-z\-']+", phrase)
    if not words:
        return "Key idea"
    # Prefer capitalized philosophical/econ terms or longest content word
    ranked = sorted(words, key=lambda w: (w[0].isupper(), len(w)), reverse=True)
    return ranked[0]


def _stable_shuffle(items: list[str], seed: str) -> list[str]:
    return sorted(items, key=lambda x: hashlib.sha1(f"{seed}:{x}".encode()).hexdigest())


def _quiz_choices(correct: str, pool: list[str], seed: str) -> tuple[list[str], int, str]:
    """Build 4 choices with the correct answer not always first."""
    distractors: list[str] = []
    for cand in _stable_shuffle(pool, seed):
        c = _clip(cand, 110)
        if c.lower() == correct.lower():
            continue
        if c in distractors:
            continue
        distractors.append(c)
        if len(distractors) >= 3:
            break
    while len(distractors) < 3:
        distractors.append(GENERIC_DISTRACTORS[len(distractors) % len(GENERIC_DISTRACTORS)])

    options = [correct] + distractors[:3]
    options = _stable_shuffle(options, seed + ":opts")
    # Ensure uniqueness after shuffle
    deduped: list[str] = []
    for o in options:
        if o not in deduped:
            deduped.append(o)
    while len(deduped) < 4:
        deduped.append(GENERIC_DISTRACTORS[len(deduped) % len(GENERIC_DISTRACTORS)])
    deduped = deduped[:4]
    answer = deduped.index(correct) if correct in deduped else 0
    if correct not in deduped:
        deduped[0] = correct
        answer = 0
    explanation = f"The overview centers on: {_clip(correct, 140)}"
    return deduped, answer, explanation


def build_bite_pack(course: CourseRecord) -> BitePack:
    """Editorial-style micro-lessons from lecture overviews (transformative, attributed)."""
    credit = (
        course.attribution.as_credit_line()
        if course.attribution
        else f"{course.professor}, {course.title} (Open course)"
    )
    bites: list[BiteCard] = []
    quizzes: list[QuizItem] = []
    order = 0

    # Pool of sentences across the course for better distractors
    all_sents: list[str] = []
    for lec in course.lectures:
        all_sents.extend(_sentences(lec.overview))
    if course.about:
        all_sents.extend(_sentences(course.about))

    if course.about:
        about_sents = _sentences(course.about)
        order += 1
        bites.append(
            BiteCard(
                id=f"{course.id}:about:hook",
                course_id=course.id,
                lecture_id="about",
                order=order,
                kind="story",
                headline=f"Why study {course.title}?",
                body=_clip(about_sents[0] if about_sents else course.about, 260),
                attribution_line=credit,
                source_url=course.url,
                license_spdx=course.license.spdx,
            )
        )
        if len(about_sents) > 1:
            order += 1
            bites.append(
                BiteCard(
                    id=f"{course.id}:about:stakes",
                    course_id=course.id,
                    lecture_id="about",
                    order=order,
                    kind="concept",
                    headline="What’s at stake",
                    body=_clip(about_sents[1], 240),
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
                    id=f"{course.id}:{lec.id}:map",
                    course_id=course.id,
                    lecture_id=lec.id,
                    order=order,
                    kind="concept",
                    headline=lec.title,
                    body=(
                        f"Session {lec.index} of {course.title}. "
                        f"Use the source lecture for the full argument; this bite marks the stop on your map."
                    ),
                    attribution_line=credit,
                    source_url=lec.url,
                    license_spdx=course.license.spdx,
                )
            )
            continue

        # 1) Hook — named after the lecture
        order += 1
        bites.append(
            BiteCard(
                id=f"{course.id}:{lec.id}:hook",
                course_id=course.id,
                lecture_id=lec.id,
                order=order,
                kind="concept",
                headline=lec.title,
                body=_clip(sents[0], 250),
                attribution_line=credit,
                source_url=lec.url,
                license_spdx=course.license.spdx,
            )
        )

        # 2) Key term — pull a salient word/phrase from the title or first sentence
        term = _title_case_term(lec.title) if len(lec.title.split()) <= 6 else _title_case_term(sents[0])
        order += 1
        bites.append(
            BiteCard(
                id=f"{course.id}:{lec.id}:term",
                course_id=course.id,
                lecture_id=lec.id,
                order=order,
                kind="key_term",
                headline=term,
                body=_clip(
                    sents[min(1, len(sents) - 1)]
                    if len(sents) > 1
                    else f"Hold onto “{term}” as you move through this session’s argument.",
                    230,
                ),
                attribution_line=credit,
                source_url=lec.url,
                license_spdx=course.license.spdx,
            )
        )

        # 3) Takeaway
        if len(sents) > 1:
            order += 1
            bites.append(
                BiteCard(
                    id=f"{course.id}:{lec.id}:takeaway",
                    course_id=course.id,
                    lecture_id=lec.id,
                    order=order,
                    kind="takeaway",
                    headline="Carry this forward",
                    body=_clip(sents[-1] if len(sents) > 2 else sents[1], 240),
                    attribution_line=credit,
                    source_url=lec.url,
                    license_spdx=course.license.spdx,
                )
            )

        # Lecture check — grounded distractors from other overviews
        correct = _clip(sents[0], 110)
        pool = [s for s in all_sents if s != sents[0]]
        choices, answer, explanation = _quiz_choices(correct, pool, f"{course.id}:{lec.id}")
        quizzes.append(
            QuizItem(
                id=f"{course.id}:{lec.id}:q1",
                course_id=course.id,
                lecture_id=lec.id,
                prompt=f"In “{lec.title}”, what is the session’s opening focus?",
                choices=choices,
                answer_index=answer,
                explanation=explanation,
            )
        )

    # Course final — synthesizes the arc (university-like)
    if course.lectures:
        titles = [lec.title for lec in course.lectures[:5]]
        arc = ", ".join(titles[:3]) + ("…" if len(titles) > 3 else "")
        correct_final = _clip(
            course.about.split(".")[0] + "."
            if course.about
            else f"{course.title} asks you to work through arguments across sessions such as {titles[0]}.",
            120,
        )
        pool = all_sents + [
            f"A survey of {course.department} methods with no link to {course.title}.",
            "A checklist of campus deadlines for the term.",
        ]
        choices, answer, explanation = _quiz_choices(correct_final, pool, f"{course.id}:final")
        quizzes.append(
            QuizItem(
                id=f"{course.id}:final",
                course_id=course.id,
                lecture_id="final",
                prompt=f"Final for {course.title}: which best states the course’s core concern?",
                choices=choices,
                answer_index=answer,
                explanation=explanation
                + (f" Early sessions include: {arc}." if arc else ""),
            )
        )

    return BitePack(course_id=course.id, bites=bites, quizzes=quizzes)
