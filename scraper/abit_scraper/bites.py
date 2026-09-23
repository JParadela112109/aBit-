from __future__ import annotations

import hashlib
import re

from .editorial import load_editorial, lecture_override
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
    ranked = sorted(words, key=lambda w: (w[0].isupper(), len(w)), reverse=True)
    return ranked[0]


def _stable_shuffle(items: list[str], seed: str) -> list[str]:
    return sorted(items, key=lambda x: hashlib.sha1(f"{seed}:{x}".encode()).hexdigest())


def _quiz_choices(correct: str, pool: list[str], seed: str) -> tuple[list[str], int, str]:
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


def _editorial_quiz_choices(
    correct: str, distractors: list[str], seed: str, explanation: str
) -> tuple[list[str], int, str]:
    options = [correct] + list(distractors)[:3]
    while len(options) < 4:
        options.append(GENERIC_DISTRACTORS[len(options) % len(GENERIC_DISTRACTORS)])
    options = _stable_shuffle(options[:4], seed)
    if correct not in options:
        options[0] = correct
    answer = options.index(correct)
    return options, answer, explanation


def build_bite_pack(course: CourseRecord) -> BitePack:
    """Micro-lessons from lecture overviews, preferring curated editorial overrides."""
    credit = (
        course.attribution.as_credit_line()
        if course.attribution
        else f"{course.professor}, {course.title} (Open course)"
    )
    editorial = load_editorial(course.id)
    bites: list[BiteCard] = []
    quizzes: list[QuizItem] = []
    order = 0

    all_sents: list[str] = []
    for lec in course.lectures:
        all_sents.extend(_sentences(lec.overview))
    if course.about:
        all_sents.extend(_sentences(course.about))

    # --- About / opening ---
    about_ed = (editorial or {}).get("about") if editorial else None
    if about_ed and about_ed.get("hook"):
        order += 1
        bites.append(
            BiteCard(
                id=f"{course.id}:about:hook",
                course_id=course.id,
                lecture_id="about",
                order=order,
                kind="story",
                headline=about_ed["hook"]["headline"],
                body=about_ed["hook"]["body"],
                attribution_line=credit,
                source_url=course.url,
                license_spdx=course.license.spdx,
            )
        )
        if about_ed.get("stakes"):
            order += 1
            bites.append(
                BiteCard(
                    id=f"{course.id}:about:stakes",
                    course_id=course.id,
                    lecture_id="about",
                    order=order,
                    kind="concept",
                    headline=about_ed["stakes"]["headline"],
                    body=about_ed["stakes"]["body"],
                    attribution_line=credit,
                    source_url=course.url,
                    license_spdx=course.license.spdx,
                )
            )
    elif course.about:
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
        ov = lecture_override(editorial, lec.index) if editorial else None
        if ov:
            order, bites, quizzes = _append_editorial_lecture(
                course, lec, ov, credit, order, bites, quizzes
            )
            continue

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

    # Course final
    final_ed = (editorial or {}).get("final") if editorial else None
    if final_ed:
        choices, answer, explanation = _editorial_quiz_choices(
            final_ed["correct"],
            final_ed.get("distractors") or [],
            f"{course.id}:final",
            final_ed.get("explanation") or "",
        )
        quizzes.append(
            QuizItem(
                id=f"{course.id}:final",
                course_id=course.id,
                lecture_id="final",
                prompt=final_ed["prompt"],
                choices=choices,
                answer_index=answer,
                explanation=explanation,
            )
        )
    elif course.lectures:
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
                explanation=explanation + (f" Early sessions include: {arc}." if arc else ""),
            )
        )

    return BitePack(course_id=course.id, bites=bites, quizzes=quizzes)


def _append_editorial_lecture(course, lec, ov, credit, order, bites, quizzes):
    hook = ov.get("hook") or {}
    term = ov.get("key_term") or {}
    take = ov.get("takeaway") or {}
    quiz = ov.get("quiz") or {}

    if hook:
        order += 1
        bites.append(
            BiteCard(
                id=f"{course.id}:{lec.id}:hook",
                course_id=course.id,
                lecture_id=lec.id,
                order=order,
                kind="concept",
                headline=hook.get("headline") or lec.title,
                body=hook.get("body") or "",
                attribution_line=credit,
                source_url=lec.url,
                license_spdx=course.license.spdx,
            )
        )
    if term:
        order += 1
        bites.append(
            BiteCard(
                id=f"{course.id}:{lec.id}:term",
                course_id=course.id,
                lecture_id=lec.id,
                order=order,
                kind="key_term",
                headline=term.get("headline") or "Key term",
                body=term.get("body") or "",
                attribution_line=credit,
                source_url=lec.url,
                license_spdx=course.license.spdx,
            )
        )
    if take:
        order += 1
        bites.append(
            BiteCard(
                id=f"{course.id}:{lec.id}:takeaway",
                course_id=course.id,
                lecture_id=lec.id,
                order=order,
                kind="takeaway",
                headline=take.get("headline") or "Carry this forward",
                body=take.get("body") or "",
                attribution_line=credit,
                source_url=lec.url,
                license_spdx=course.license.spdx,
            )
        )
    if quiz.get("correct"):
        choices, answer, explanation = _editorial_quiz_choices(
            quiz["correct"],
            quiz.get("distractors") or [],
            f"{course.id}:{lec.id}",
            quiz.get("explanation") or "",
        )
        quizzes.append(
            QuizItem(
                id=f"{course.id}:{lec.id}:q1",
                course_id=course.id,
                lecture_id=lec.id,
                prompt=quiz.get("prompt") or f"In “{lec.title}”, what matters most?",
                choices=choices,
                answer_index=answer,
                explanation=explanation,
            )
        )
    return order, bites, quizzes
