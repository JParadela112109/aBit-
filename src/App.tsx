import { useEffect, useMemo, useState } from 'react'
import './App.css'

const DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'] as const
const STORAGE_KEY = 'abit-week-v1'

type HabitId = 'move' | 'meal' | 'focus'

type Habit = {
  id: HabitId
  name: string
}

const HABITS: Habit[] = [
  { id: 'move', name: 'Move a bit' },
  { id: 'meal', name: 'Eat with intention' },
  { id: 'focus', name: 'One deep focus block' },
]

type WeekState = Record<HabitId, boolean[]>

function emptyWeek(): WeekState {
  return {
    move: Array(7).fill(false),
    meal: Array(7).fill(false),
    focus: Array(7).fill(false),
  }
}

function loadWeek(): WeekState {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) {
      const start = emptyWeek()
      start.move[0] = true
      start.move[1] = true
      start.meal[0] = true
      start.focus[1] = true
      return start
    }
    const parsed = JSON.parse(raw) as WeekState
    return {
      move: parsed.move ?? Array(7).fill(false),
      meal: parsed.meal ?? Array(7).fill(false),
      focus: parsed.focus ?? Array(7).fill(false),
    }
  } catch {
    return emptyWeek()
  }
}

function countDone(week: WeekState) {
  return Object.values(week).reduce(
    (sum, days) => sum + days.filter(Boolean).length,
    0,
  )
}

function App() {
  const [week, setWeek] = useState<WeekState>(loadWeek)

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(week))
  }, [week])

  const done = useMemo(() => countDone(week), [week])
  const total = HABITS.length * 7

  function toggle(habitId: HabitId, dayIndex: number) {
    setWeek((prev) => {
      const next = { ...prev, [habitId]: [...prev[habitId]] }
      next[habitId][dayIndex] = !next[habitId][dayIndex]
      return next
    })
  }

  return (
    <div className="app">
      <header className="site-header">
        <a className="brand" href="#top" aria-label="aBit home">
          a<span>B</span>it
        </a>
        <a className="nav-cta" href="#tracker">
          Start today
        </a>
      </header>

      <main id="top">
        <section className="hero" aria-label="aBit hero">
          <div className="hero-media" aria-hidden="true">
            <img
              src="https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=2400&q=80"
              alt=""
            />
          </div>
          <div className="hero-scrim" aria-hidden="true" />
          <div className="hero-copy">
            <span className="brand">
              a<span>B</span>it
            </span>
            <h1>Build better habits, a bit at a time.</h1>
            <p>
              Skip the overload. Track tiny daily wins for food, movement, and
              focus — enough to keep going, never enough to burn out.
            </p>
            <div className="cta-row">
              <a className="btn-primary" href="#tracker">
                Begin with one bit
              </a>
              <a className="btn-ghost" href="#idea">
                How it works
              </a>
            </div>
          </div>
        </section>

        <section className="section idea" id="idea">
          <div className="section-inner">
            <h2>Small bits compound.</h2>
            <p className="section-lead">
              aBit turns consistency into a simple grid — fill a square, keep
              the streak, feel the picture of your week take shape.
            </p>

            <div className="idea-grid">
              <div className="idea-visual">
                <span
                  className="glow"
                  style={{ top: '-2rem', left: '-1rem' }}
                  aria-hidden="true"
                />
                <img
                  src="https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&w=1600&q=80"
                  alt="Morning movement and a calm start to the day"
                />
              </div>
              <div className="bit-legend">
                <p>
                  Each square is a single action. No calorie math. No rigid
                  plans. Just proof you showed up — one bit, then another.
                </p>
                <div className="bit-row" aria-hidden="true">
                  <span className="bit on" />
                  <span className="bit on" />
                  <span className="bit mid" />
                  <span className="bit" />
                  <span className="bit" />
                  <span className="bit on" />
                  <span className="bit" />
                </div>
              </div>
            </div>
          </div>
        </section>

        <section className="section tracker" id="tracker">
          <div className="section-inner">
            <h2>This week’s bits</h2>
            <p className="section-lead">
              Tap a day to mark it done. Your progress stays in this browser for
              now — a living prototype of the aBit rhythm.
            </p>

            <div className="tracker-panel">
              {HABITS.map((habit) => (
                <article className="habit" key={habit.id}>
                  <div className="habit-head">
                    <h3 className="habit-name">{habit.name}</h3>
                    <span className="habit-meta">
                      {week[habit.id].filter(Boolean).length}/7
                    </span>
                  </div>
                  <div
                    className="day-grid"
                    role="group"
                    aria-label={`${habit.name} this week`}
                  >
                    {week[habit.id].map((doneDay, index) => (
                      <button
                        key={`${habit.id}-${index}`}
                        type="button"
                        className={`day-btn${doneDay ? ' done' : ''}`}
                        aria-pressed={doneDay}
                        aria-label={`${DAYS[index]} ${doneDay ? 'done' : 'not done'}`}
                        onClick={() => toggle(habit.id, index)}
                      />
                    ))}
                  </div>
                  <div className="day-labels" aria-hidden="true">
                    {DAYS.map((day) => (
                      <span key={day}>{day}</span>
                    ))}
                  </div>
                </article>
              ))}
            </div>

            <div className="streak">
              <strong>
                {done}/{total}
              </strong>
              <span>bits filled this week — keep the grid growing.</span>
            </div>
          </div>
        </section>
      </main>

      <footer className="footer">
        <div className="footer-inner">
          <span className="brand">
            a<span>B</span>it
          </span>
          <span>Start small. Stay consistent.</span>
        </div>
      </footer>
    </div>
  )
}

export default App
