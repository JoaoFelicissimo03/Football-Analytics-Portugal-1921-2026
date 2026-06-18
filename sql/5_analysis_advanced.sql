-- ============================================================
--  PROJECT  : Football Analytics — Portugal 1921–2026
--  SCRIPT   : 05_analysis_advanced.sql
--  PURPOSE  : Advanced Metrics — Sequences & Defensive Record
--  DATABASE : football_analytics
--  AUTHOR   : João Felicíssimo
--  DATE     : June 2026
-- ============================================================

-- ============================================================
--  BLOCK D — ADVANCED METRICS
--
--  D1 — Clean sheets per era
--  D2 — Comeback wins per era
--  D3 — Longest winning streaks per era
--  D4 — Longest unbeaten runs per era
-- ============================================================


-- ------------------------------------------------------------
--  D1 — Clean Sheets Per Era
-- ------------------------------------------------------------
WITH era_classification AS (
    SELECT *,
        CASE
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1921 AND 1960 THEN '1 - Struggle Years'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1961 AND 1974 THEN '2 - The Eusebio Era'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1975 AND 1993 THEN '3 - The Rebuilding Years'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1994 AND 2010 THEN '4 - The Golden Generation'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 2011 AND 2026 THEN '5 - The Modern Era'
        END AS era
    FROM results
    WHERE home_team = 'Portugal' OR away_team = 'Portugal'
)
SELECT
    era,
    COUNT(*) AS total_matches,
    SUM(CASE
        WHEN home_team = 'Portugal' AND away_score = 0 THEN 1
        WHEN away_team = 'Portugal' AND home_score = 0 THEN 1
        ELSE 0 END) AS clean_sheets,
    ROUND(SUM(CASE
        WHEN home_team = 'Portugal' AND away_score = 0 THEN 1
        WHEN away_team = 'Portugal' AND home_score = 0 THEN 1
        ELSE 0 END)::NUMERIC / COUNT(*) * 100, 2) AS clean_sheet_pct
FROM era_classification
GROUP BY era
ORDER BY era;

-- D1 FINDINGS: Clean sheet rate climbs steadily from 16.50% (Era 1)
-- to a peak of 49.74% (Era 4) — nearly half of all matches.
-- Era 5 (47.64%) is close behind but slightly lower, consistent
-- with C1's finding that Era 4 was marginally more defensively solid.
-- Almost 1 in 2 games ended goalless-against in Eras 4 and 5,
-- vs roughly 1 in 6 in Era 1.

-- ------------------------------------------------------------
--  D2 — Comeback Wins Per Era
-- ------------------------------------------------------------
WITH era_classification AS (
    SELECT *,
        CASE
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1921 AND 1960 THEN '1 - Struggle Years'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1961 AND 1974 THEN '2 - The Eusebio Era'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1975 AND 1993 THEN '3 - The Rebuilding Years'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1994 AND 2010 THEN '4 - The Golden Generation'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 2011 AND 2026 THEN '5 - The Modern Era'
        END AS era
    FROM results
    WHERE home_team = 'Portugal' OR away_team = 'Portugal'
),
first_scorer AS (
    SELECT DISTINCT ON (date, home_team, away_team)
        date, 
		home_team, 
		away_team, 
		team AS first_scoring_team
    FROM goalscorers
    WHERE (home_team = 'Portugal' OR away_team = 'Portugal')
      AND minute IS NOT NULL AND minute NOT LIKE '%+%'
    ORDER BY date, home_team, away_team, CAST(minute AS INTEGER)
)
SELECT
    e.era,
    COUNT(*) AS comeback_wins
FROM era_classification e
JOIN first_scorer f
    ON e.date = f.date AND e.home_team = f.home_team AND e.away_team = f.away_team
WHERE f.first_scoring_team <> 'Portugal'
  AND (
      (e.home_team = 'Portugal' AND e.home_score > e.away_score)
      OR (e.away_team = 'Portugal' AND e.away_score > e.home_score)
  )
GROUP BY e.era
ORDER BY e.era;

-- D2 FINDINGS: Comeback wins grow sharply in recent eras —
-- only 1 in Era 1 and Era 2, rising to 12 in Era 5.
-- Era 5 alone has as many comeback wins as Eras 1-4 combined (9).
-- This likely reflects both more matches played and a squad
-- with the attacking depth to recover from going behind —
-- a trait strongly associated with the CR7-era team.

-- ------------------------------------------------------------
--  D3 — Longest Winning Streaks Per Era
-- ------------------------------------------------------------
WITH era_classification AS (
    SELECT *,
        CASE
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1921 AND 1960 THEN '1 - Struggle Years'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1961 AND 1974 THEN '2 - The Eusebio Era'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1975 AND 1993 THEN '3 - The Rebuilding Years'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1994 AND 2010 THEN '4 - The Golden Generation'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 2011 AND 2026 THEN '5 - The Modern Era'
        END AS era,
        CASE
            WHEN home_team = 'Portugal' AND home_score > away_score THEN 1
            WHEN away_team = 'Portugal' AND away_score > home_score THEN 1
            ELSE 0
        END AS is_win
    FROM results
    WHERE home_team = 'Portugal' OR away_team = 'Portugal'
),
sequenced AS (
    SELECT *,
        ROW_NUMBER() OVER (ORDER BY date) AS rn_all,
        CASE WHEN is_win = 1
            THEN ROW_NUMBER() OVER (PARTITION BY is_win ORDER BY date)
            ELSE NULL
        END AS rn_wins
    FROM era_classification
),
islands AS (
    SELECT *, (rn_all - rn_wins) AS island_key
    FROM sequenced
    WHERE is_win = 1
)
SELECT era, MAX(streak_length) AS longest_winning_streak
FROM (
    SELECT era, island_key, COUNT(*) AS streak_length
    FROM islands
    GROUP BY era, island_key
) t
GROUP BY era
ORDER BY era;

-- D3 FINDINGS: Longest winning streaks peak in Era 5 (11 games)
-- and Era 2 (9 games) — both eras associated with a standout
-- generation (CR7, Eusébio). Era 1 never exceeded 3 consecutive
-- wins. Era 3's streak of 5 is the weakest of the "modern" eras,
-- reinforcing its identity as a rebuilding period without
-- a dominant run of form.

-- ------------------------------------------------------------
--  D4 — Longest Unbeaten Runs Per Era
-- ------------------------------------------------------------
WITH era_classification AS (
    SELECT *,
        CASE
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1921 AND 1960 THEN '1 - Struggle Years'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1961 AND 1974 THEN '2 - The Eusebio Era'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1975 AND 1993 THEN '3 - The Rebuilding Years'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1994 AND 2010 THEN '4 - The Golden Generation'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 2011 AND 2026 THEN '5 - The Modern Era'
        END AS era,
        CASE
            WHEN home_team = 'Portugal' AND home_score < away_score THEN 0
            WHEN away_team = 'Portugal' AND away_score < home_score THEN 0
            ELSE 1
        END AS is_unbeaten
    FROM results
    WHERE home_team = 'Portugal' OR away_team = 'Portugal'
),
sequenced AS (
    SELECT *,
        ROW_NUMBER() OVER (ORDER BY date) AS rn_all,
        CASE WHEN is_unbeaten = 1
            THEN ROW_NUMBER() OVER (PARTITION BY is_unbeaten ORDER BY date)
            ELSE NULL
        END AS rn_unbeaten
    FROM era_classification
),
islands AS (
    SELECT *, (rn_all - rn_unbeaten) AS island_key
    FROM sequenced
    WHERE is_unbeaten = 1
)
SELECT era, MAX(streak_length) AS longest_unbeaten_run
FROM (
    SELECT era, island_key, COUNT(*) AS streak_length
    FROM islands
    GROUP BY era, island_key
) t
GROUP BY era
ORDER BY era;

-- D4 FINDINGS: Era 4 holds the record for longest unbeaten run
-- (19 games) — even longer than Era 5's 14. Combined with D1's
-- clean sheet rate (49.74%, the highest), this is the strongest
-- evidence yet that Era 4 was Portugal's most defensively
-- dominant period, even if Era 5 has the higher overall win rate.

-- ============================================================
--  ADVANCED METRICS SUMMARY
--
--  D1 — Clean sheets peak in Era 4 (49.74%) and Era 5 (47.64%),
--  nearly 3x Era 1's rate (16.50%).
--
--  D2 — Comeback wins are almost exclusively a modern phenomenon:
--  12 in Era 5 alone vs 9 across the previous four eras combined.
--
--  D3 — Longest winning streaks: Era 5 (11) and Era 2 (9) stand
--  out as the two eras most associated with a single dominant
--  generation (CR7, Eusébio).
--
--  D4 — Longest unbeaten run belongs to Era 4 (19 games) —
--  longer than Era 5's 14, reinforcing Era 4 as the most
--  defensively consistent era in Portugal's history.
--
--  REVISED ANSWER TO THE CENTRAL QUESTION:
--  Era 4 (Golden Generation) now leads on THREE defensive/
--  consistency metrics: lowest goals conceded (C1), best
--  clean sheet rate (D1), and longest unbeaten run (D4).
--  Era 5 (Modern Era) leads on THREE attacking/results metrics:
--  highest win rate (C1), most comeback wins (D2), and longest
--  winning streak (D3).
--  The data splits almost perfectly along attack vs defence —
--  Era 4 is Portugal's best defensive generation, Era 5 is its
--  best attacking and highest-achieving generation.
--
--  END OF SQL ANALYSIS PHASE.
--  Next: Power BI dashboard.
-- ============================================================