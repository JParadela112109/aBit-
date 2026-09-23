from __future__ import annotations

from datetime import datetime, timezone
from typing import Literal

from pydantic import BaseModel, Field, HttpUrl


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class LicenseInfo(BaseModel):
    spdx: str = "CC-BY-NC-SA-3.0"
    name: str = "Creative Commons Attribution-NonCommercial-ShareAlike 3.0"
    url: str = "https://creativecommons.org/licenses/by-nc-sa/3.0/us/"
    commercial_ok: bool = False
    notes: str = ""


class Attribution(BaseModel):
    faculty: str
    course_title: str
    institution: str
    project: str
    source_url: str
    accessed_at: datetime = Field(default_factory=utc_now)

    def as_credit_line(self) -> str:
        date = self.accessed_at.strftime("%B %d, %Y")
        return (
            f"{self.faculty}, {self.course_title} "
            f"({self.institution}: {self.project}), {self.source_url} "
            f"(Accessed {date}). License: Creative Commons BY-NC-SA"
        )


class LectureOutline(BaseModel):
    id: str
    index: int
    title: str
    path: str
    url: str
    overview: str = ""


class CourseRecord(BaseModel):
    id: str
    source: Literal["yale", "mit", "other"]
    department: str
    number: str
    title: str
    professor: str
    term: str = ""
    path: str
    url: str
    about: str = ""
    lectures: list[LectureOutline] = Field(default_factory=list)
    license: LicenseInfo = Field(default_factory=LicenseInfo)
    attribution: Attribution | None = None


class Catalog(BaseModel):
    source: str
    scraped_at: datetime = Field(default_factory=utc_now)
    course_count: int = 0
    courses: list[CourseRecord] = Field(default_factory=list)


class BiteCard(BaseModel):
    id: str
    course_id: str
    lecture_id: str
    order: int
    kind: Literal["concept", "story", "key_term", "takeaway"] = "concept"
    headline: str
    body: str
    attribution_line: str
    source_url: str
    license_spdx: str = "CC-BY-NC-SA-3.0"


class QuizItem(BaseModel):
    id: str
    course_id: str
    lecture_id: str
    prompt: str
    choices: list[str]
    answer_index: int
    explanation: str = ""


class BitePack(BaseModel):
    course_id: str
    generated_at: datetime = Field(default_factory=utc_now)
    bites: list[BiteCard] = Field(default_factory=list)
    quizzes: list[QuizItem] = Field(default_factory=list)
