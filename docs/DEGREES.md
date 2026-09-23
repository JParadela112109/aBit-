# How degrees work (aBit College)

aBit degrees are meant to **feel like a real university** — programs, credits, grades, transcripts, graduation — while staying clearly **not accredited**.

## Mental model

```text
Bites + lecture checks
        ↓
Course grade + credits  →  Transcript + GPA
        ↓
Program requirements (required + electives)
        ↓
Eligible to commence  →  Conferred credential
```

Finishing bites in **one** course is **not** a degree. A degree is a **program** with requirements.

## Passing a course

| Rule | Threshold |
| --- | --- |
| Bite completion | ≥ **80%** |
| Lecture-check pass rate | ≥ **70%** of lecture quizzes (final excluded) |
| Course final | Must **pass** if the bundle includes one |
| Letter grade | Composite: **40%** bites + **60%** lecture checks |

Grades: A / A- / B+ / B / B- / C+ / C / C- / D / F (4.0 scale).  
**F**, missing a threshold, or a failed/missing final ⇒ no credits toward a program.

## Programs (shipped)

Defined in `ios/ABit/Resources/Academic/programs.json` (editable, drop-in):

1. **B.A. in Liberal Arts** — pass Death + Intro Psych + Financial Markets (12 credits, GPA ≥ 2.0)
2. **B.A. in Philosophy** — pass Death + 4 elective credits from Psych/Markets (8 credits)
3. **Certificate · Mind & Markets** — pass Psych + 4 elective credits (8 credits)

### Requirement kinds

- **required** — every listed course must be **passed**
- **elective** — earn at least `min_credits` from the pool

### Prerequisites

Optional map in `programs.json`:

```json
"prerequisites": {
  "yale:econ-252": ["yale:psyc-110"]
}
```

Locked courses show on the course screen until prereqs pass.

## Graduation

1. Enroll in a program (College tab)
2. Pass the required / elective courses
3. Meet **min credits** and **min GPA**
4. Tap **Commence** — credential is conferred and stored locally

## Adding / editing programs

Edit `Resources/Academic/programs.json`, rebuild. No Swift changes needed for new combinations of existing course IDs.

When you scrape a new course, add its id to `course_credits` and to the relevant requirement pools.
