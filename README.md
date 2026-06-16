# Football Analytics — Portugal 1921–2026

A SQL analysis of Portugal's international football history across 150 years and five distinct eras — from the Eusébio generation to the modern CR7 era — using PostgreSQL and a dataset of 49,000+ international matches.

> **Status:** SQL analysis phase complete. Power BI dashboard in progress.

---

## Central Question

**How did Portugal evolve in international football from 1921 to today?**

The analysis breaks Portugal's history into five eras — defined empirically from rolling 5-year win rate and defensive trends, not assumptions — and compares them across win rate, goals, tournament performance, scoring patterns, and sequence-based metrics (streaks, comebacks, clean sheets).

---

## The Five Eras

| Era | Period | Win Rate | Goals Conceded/Game |
|-----|--------|----------|----------------------|
| 1 — Struggle Years | 1921–1960 | 29.13% | 2.24 |
| 2 — The Eusébio Era | 1961–1974 | 44.87% | 1.15 |
| 3 — The Rebuilding Years | 1975–1993 | 43.94% | 1.13 |
| 4 — The Golden Generation | 1994–2010 | 57.14% | 0.78 |
| 5 — The Modern Era | 2011–2026 | 60.73% | 0.83 |

---

## Dataset

Source: [International Football Results 1872–2026](https://www.kaggle.com/datasets/martj42/international-football-results-from-1872-to-2017) (Kaggle, martj42)

| Table | Rows | Notes |
|-------|------|-------|
| `results` | 49,281 | Main match data |
| `goalscorers` | 47,601 | Scorer, minute, own goal, penalty flags |
| `shootouts` | 675 | Date format normalised from DD/MM/YYYY |
| `former_names` | 36 | Historical country name lookup |

---

## Tech Stack

- **PostgreSQL 16** — data cleaning, transformation, and analysis
- **Power BI** — dashboard (in progress)

---

## Project Structure

```
sql/
  1_setup.sql               — create tables + import CSVs
  2_cleaning.sql            — data quality audit and fixes
  3_exploration.sql         — initial exploration and profiling
  4_analysis_eras.sql       — era breakdown and scorecard
  5_analysis_advanced.sql   — streaks, comebacks, clean sheets
docs/
  index.html                — project documentation
README.md
```

---

## Key Findings

- Portugal's win rate more than doubled between Era 1 (29.13%) and Era 5 (60.73%).
- The sharpest single improvement was defensive: goals conceded per game dropped from 2.24 to 0.78 between Era 1 and Era 4.
- Era 1 (1921–1960) failed to qualify for any of the 6 World Cups held during that period.
- The 1966 World Cup (Eusébio era) remains Portugal's best campaign by win rate: 83.33%, finishing 3rd.
- Clean sheet rate climbs from 16.50% (Era 1) to a peak of 49.74% (Era 4) — nearly half of all matches.
- Era 4 holds Portugal's longest unbeaten run in history: 19 consecutive games without defeat.
- Era 5 has the most comeback wins (12) — more than the previous four eras combined (9).
- Era 5's longest winning streak (11 games) is the highest in history, narrowly ahead of Era 2's 9.
- Cristiano Ronaldo scored 99 goals in Era 5 alone — almost 5x the next highest scorer in that era.

### So — which era is the golden generation?

The data splits almost perfectly down the middle:

| | Era 4 — Golden Generation | Era 5 — Modern Era |
|---|---|---|
| **Wins on** | Goals conceded/game (0.78) | Win rate (60.73%) |
| | Clean sheet rate (49.74%) | Comeback wins (12) |
| | Longest unbeaten run (19) | Longest winning streak (11) |

**Era 4 is Portugal's best defensive generation. Era 5 is its best attacking and highest-achieving generation.** There is no single winner — and that ambiguity is one of the project's most interesting findings.

---

## Notes on Data Limitations

- `rankings.csv` (FIFA rankings) was not included in this dataset version — ranking-based analysis was removed from scope.
- Eusébio's goal tally in this dataset is 26; the official FPF record is 41. The discrepancy is due to incomplete goalscorer coverage for matches before ~1968. Team-level metrics (win rate, goals scored/conceded) are unaffected.
- Home/away analysis was excluded — the `home_team` field reflects the dataset's designated "home" side, not the actual host nation, especially for tournaments hosted in neutral countries.

---

## Next Steps

- [x] Finish `5_analysis_advanced.sql` (streaks, comebacks, clean sheets)
- [ ] Connect PostgreSQL to Power BI
- [ ] Build single-page dashboard with era slicer
- [ ] Publish dashboard and add link here
