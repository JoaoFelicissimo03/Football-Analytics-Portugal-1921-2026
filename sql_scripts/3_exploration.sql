-- ============================================================
--  PROJECT  : Football Analytics — Portugal 1921–2026
--  SCRIPT   : 3_exploration.sql
--  PURPOSE  : Data Cleaning, Quality Audit & Initial Exploration
--  DATABASE : football_analytics
--  AUTHOR   : João Felicíssimo
--  DATE     : June 2026
-- ============================================================

-- ============================================================
--  BLOCK B — INITIAL EXPLORATION
--  Goal: understand the shape, volume, and distribution
--  of the data before writing analysis queries.
--  These queries answer "what do we have?" not "what does
--  it mean?" — that comes in the analysis scripts.
-- ============================================================


-- ------------------------------------------------------------
--  B1 — Total Matches Involving Portugal
--  How many matches has Portugal played in total,
--  and how does that break down by home vs away?
-- ------------------------------------------------------------

SELECT
	COUNT(*) AS overall_matches,
	SUM(CASE WHEN home_team = 'Portugal' THEN 1 ELSE 0 END) AS home_matches,
	SUM(CASE WHEN away_team = 'Portugal' THEN 1 ELSE 0 END) AS away_matches
FROM results
WHERE home_team = 'Portugal' OR away_team = 'Portugal';

-- B1 FINDINGS: Portugal played 693 matches in total.
-- Slightly more home (367) than away (326) — roughly 53/47 split.


-- ------------------------------------------------------------
--  B2 — Portugal Matches Per Decade
--  How many matches did Portugal play in each decade?
-- ------------------------------------------------------------

SELECT
	(EXTRACT(YEAR FROM date)::INT / 10) * 10 AS decade,
	COUNT(*) AS overall_matches,
	SUM(CASE WHEN home_team = 'Portugal' THEN 1 ELSE 0 END) AS home_matches,
	SUM(CASE WHEN away_team = 'Portugal' THEN 1 ELSE 0 END) AS away_matches
FROM results
WHERE home_team = 'Portugal' OR away_team = 'Portugal'
GROUP BY decade
ORDER BY decade;

-- B2 FINDINGS: Match volume grew consistently from the 1920s to the 2010s.
-- The 2020s are incomplete (dataset cuts off mid-decade).
-- Fewest matches in the early decades — less data to work with pre-1960.

-- ------------------------------------------------------------
--  B3 — Tournament Distribution for Portugal
--  Which tournaments appear most often in Portugal's record?
-- ------------------------------------------------------------

SELECT 
	tournament,
	COUNT(*) AS matches
FROM results
WHERE home_team = 'Portugal' OR away_team = 'Portugal'
GROUP BY tournament
ORDER BY matches DESC;

-- B3 FINDINGS: 287 friendlies vs 406 competitive matches.
-- Competitive split: WC qualification (155) + Euro qualification (125)
-- + UEFA Euro (44) + World Cup (35) + Nations League (28).
-- Important: friendly results will need to be separated from competitive
-- in the era analysis to avoid skewing win rates.

-- ------------------------------------------------------------
--  B4 — Portugal's Overall Record (all-time)
--  Total wins, draws, losses, goals scored, and goals
--  conceded across all 693 matches.
-- ------------------------------------------------------------

SELECT
	SUM(CASE WHEN (home_team = 'Portugal' AND home_score > away_score) OR 
		(away_team = 'Portugal' AND home_score < away_score) THEN 1 ELSE 0 END) AS Wins,
	SUM(CASE WHEN home_score = away_score THEN 1 ELSE 0 END) AS Draws,
	SUM(CASE WHEN (home_team = 'Portugal' AND home_score < away_score) OR 
		(away_team = 'Portugal' AND home_score > away_score) THEN 1 ELSE 0 END) AS Losses,
	SUM(CASE WHEN home_team = 'Portugal' THEN home_score
		WHEN away_team = 'Portugal' THEN away_score ELSE 0 END) AS Goals_scored,
	SUM(CASE WHEN home_team = 'Portugal' THEN away_score
		WHEN away_team = 'Portugal' THEN home_score ELSE 0 END) AS Goals_conceded
FROM results
WHERE home_team = 'Portugal' OR away_team = 'Portugal';

-- B4 FINDINGS: All-time record — 347W 159D 187L.
-- Goals scored: 1223 | Goals conceded: 776.
-- Overall win rate: 50.07% — Portugal wins more than it loses all-time.

-- ------------------------------------------------------------
--  B5 — Portugal's Overall Record Per Decade + Win Rate
-- ------------------------------------------------------------

WITH portugal_stats AS (
	SELECT
		(EXTRACT(YEAR FROM date)::INT / 10) * 10 AS decade,
		COUNT(*) AS overall_matches,
		SUM(CASE WHEN (home_team = 'Portugal' AND home_score > away_score) OR 
			(away_team = 'Portugal' AND home_score < away_score) THEN 1 ELSE 0 END) AS Wins,
		SUM(CASE WHEN home_score = away_score THEN 1 ELSE 0 END) AS Draws,
		SUM(CASE WHEN (home_team = 'Portugal' AND home_score < away_score) OR 
			(away_team = 'Portugal' AND home_score > away_score) THEN 1 ELSE 0 END) AS Losses,
		SUM(CASE WHEN home_team = 'Portugal' THEN home_score
			WHEN away_team = 'Portugal' THEN away_score ELSE 0 END) AS Goals_scored,
		SUM(CASE WHEN home_team = 'Portugal' THEN away_score
			WHEN away_team = 'Portugal' THEN home_score ELSE 0 END) AS Goals_conceded
	FROM results
	WHERE home_team = 'Portugal' OR away_team = 'Portugal'
	GROUP BY decade
) 
	
SELECT
    decade,
    overall_matches,
    Wins,
    Draws,
    Losses,
    Goals_scored,
    Goals_conceded,
    ROUND((Wins::NUMERIC / overall_matches) * 100, 2) AS win_rate_percent
FROM portugal_stats
ORDER BY decade;

-- B5 FINDINGS: Win rate tells a clear story by decade.
-- 1920s–1950s: struggling (22–38% WR), conceding heavily.
-- 1960s–1970s: first emergence (43–50% WR) — Eusébio era visible.
-- 1980s: regression (40% WR) — the wilderness years confirmed by data.
-- 1990s onwards: sustained improvement (51% → 64% WR).
-- Goals conceded drop dramatically from 1990s — defensive solidity emerges.
-- Note: B5 repurposed from era breakdown to decade breakdown — eras
-- will be formally defined and analysed in 4_analysis_eras.sql.


-- ------------------------------------------------------------
--  B6 — Top Opponents by Number of Matches
--  Which countries has Portugal played the most? And records?
-- ------------------------------------------------------------

WITH opponents_list AS (
    -- Portugal is Home, Opponent is Away
    SELECT 
        away_team AS opponent,
        home_score AS portugal_score,
        away_score AS opponent_score,
        date
    FROM results
    WHERE home_team = 'Portugal'

    UNION ALL

    -- Portugal is Away, Opponent is Home
    SELECT 
        home_team AS opponent,
        away_score AS portugal_score,
        home_score AS opponent_score,
        date
    FROM results
    WHERE away_team = 'Portugal'
), 
opponents_results AS (
SELECT
    opponent,
    COUNT(*) AS matches_played,
    SUM(CASE WHEN portugal_score > opponent_score THEN 1 ELSE 0 END) AS wins,
    SUM(CASE WHEN portugal_score = opponent_score THEN 1 ELSE 0 END) AS draws,
    SUM(CASE WHEN portugal_score < opponent_score THEN 1 ELSE 0 END) AS losses,
    SUM(portugal_score) AS goals_scored,
    SUM(opponent_score) AS goals_conceded
FROM opponents_list
GROUP BY opponent
)

SELECT
	opponent,
	matches_played,
	wins,
	draws,
	losses,
	goals_scored,
	goals_conceded,
	ROUND((wins::NUMERIC / matches_played) * 100, 2) AS win_rate_percent
FROM opponents_results
ORDER BY matches_played DESC
LIMIT 10;

-- B6 FINDINGS: Spain is Portugal's most frequent opponent (42 matches)
-- with the worst win rate (19.05%) — historic rivalry confirmed.
-- England is the toughest by win rate: only 13.04% (3W 10D 10L).
-- Luxembourg is the "easiest": 90.48% WR — 19 wins from 21 matches.
-- Brazil: 4W 3D 14L — Portugal loses far more than it wins against Brazil.


-- ------------------------------------------------------------
--  B7 — Goalscorers: Top 10 Portugal Scorers All-Time
--  Who are Portugal's top 10 scorers in the dataset?
-- ------------------------------------------------------------

SELECT
	scorer,
	COUNT(*) total_goals
FROM goalscorers
WHERE team = 'Portugal'
GROUP BY scorer
ORDER BY  total_goals DESC
LIMIT 10;

-- B7 FINDINGS: CR7 dominates with 121 goals — nearly 5x the next scorer.
-- Eusébio (26) and Pauleta (25) are essentially tied for second.
-- Bruno Fernandes closing in on second place too.

-- NOTE: Eusébio's goal tally in this dataset is 26.
-- The FPF official record is 41 goals (1961–1973).
-- The discrepancy is due to incomplete goalscorer coverage
-- for matches played before ~1968 in this dataset.
-- All team-level metrics (win rate, goals scored/conceded)
-- are unaffected — only individual scorer counts are impacted.

-- ------------------------------------------------------------
--  B8 — Shootouts: Portugal's Penalty Record
--  How many penalty shootouts has Portugal been involved in,
--  and what is the win/loss outcome of each?
-- ------------------------------------------------------------

SELECT
	COUNT(*) overall,
	SUM(CASE WHEN winner = 'Portugal' THEN 1 ELSE 0 END) AS Wins,
	SUM(CASE WHEN winner <> 'Portugal' THEN 1 ELSE 0 END) AS Losses,
	ROUND((SUM(CASE WHEN winner = 'Portugal' THEN 1 ELSE 0 END)::NUMERIC / COUNT(*)) * 100, 2) AS win_rate_percent
FROM shootouts
WHERE home_team = 'Portugal' OR away_team = 'Portugal';

-- B8 FINDINGS: Portugal has been in 8 penalty shootouts — 5W 3L (62.50%).
-- Solid record. First_shooter advantage and tournament context
-- will be explored in 5_analysis_advanced.sql.


-- ============================================================
--  EXPLORATION SUMMARY
--
--  693 matches played by Portugal between 1921 and 2026.
--
--  KEY FINDINGS:
--
--  Volume
--  - Match volume grew from ~20/decade (1920s–1940s) to
--    127–128/decade (2000s–2010s), reflecting the expansion
--    of international football.
--
--  Performance trend
--  - Win rate rose from 22–38% (1920s–1950s) to 64% (2020s).
--  - Goals conceded dropped sharply from the 1990s onward —
--    the single clearest signal of a generational shift.
--  - The 1980s show a visible regression (40% WR) between
--    the Eusébio era and the Golden Generation.
--
--  Opponents
--  - Most frequent: Spain (42 matches), France (27), Italy (27).
--  - Toughest record: England (13.04% WR).
--  - Easiest record: Luxembourg (90.48% WR).
--
--  Scorers
--  - CR7: 121 goals — in a different category from everyone else.
--  - Eusébio (26) and Pauleta (25) tied for second.
--
--  Tournaments
--  - 406 competitive matches vs 287 friendlies.
--  - Separation of competitive vs friendly results will be
--    applied in all era analysis queries.
--
--  Shootouts
--  - 8 total | 5W 3L | 62.50% win rate.
--
--  DATASET IS READY FOR ERA ANALYSIS.
--  Next: 4_analysis_eras.sql
-- ============================================================
