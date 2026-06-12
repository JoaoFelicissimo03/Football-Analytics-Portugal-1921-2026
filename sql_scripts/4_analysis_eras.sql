-- ============================================================
--  PROJECT  : Football Analytics — Portugal 1921–2026
--  SCRIPT   : 04_analysis_eras.sql
--  PURPOSE  : Portugal Performance Analysis by Era
--  DATABASE : football_analytics
--  AUTHOR   : João Felicíssimo
--  DATE     : June 2026
-- ============================================================

-- ============================================================
--  BLOCK C — ERA ANALYSIS
--
--  This script is organised in the following order:
--
--  C0  — Breakpoint analysis (rolling 5-year windows)
--        Run this first. The output is the empirical basis
--        for all era definitions below.
--
--  ERA DEFINITIONS — defined after C0, justified by its output.
--
--  C1  — Core record per era (all matches)
--  C2  — Competitive matches only per era
--  C3  — Home vs away record per era
--  C4  — World Cup record per era
--  C5  — UEFA Euro record per era
--  C6  — Best and worst tournament campaigns
--  C7  — Top scorers per era
--  C8  — First half vs second half goals per era
--  C9  — Penalty goals per era
--  C10 — Record against top 5 historical opponents per era
--  C11 — Biggest wins per era
--  C12 — Biggest defeats per era
--  C13 — Era scorecard: all key metrics side by side
-- ============================================================


-- ------------------------------------------------------------
--  C0 — Rolling 5-Year Performance Breakpoint Analysis
--
--  Calculates Portugal's rolling 5-year win rate and goals
--  conceded per game across the full history (1921–2026).
--
--  HOW TO READ THE OUTPUT:
--  Look for sudden jumps in win rate and drops in GA/game.
--  These breakpoints are what define the era boundaries.
--  Expected signals:
--    - WR jumps from ~28% to ~57% around 1962–1966
--    - WR drops back to ~40% around 1974–1980
--    - GA/game falls below 1.0 and stays there from ~1990
--    - WR crosses 60% consistently from ~1996 onwards
--    - WR reaches 65–67% in the most recent windows
-- ------------------------------------------------------------

WITH portugal_stats AS(

SELECT
	EXTRACT(YEAR FROM date) AS year,
	COUNT(*) AS total_games,
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
GROUP BY year
)

SELECT
    year,
    -- Rolling 5-Year Averages
    ROUND(AVG(total_games) OVER (ORDER BY year ROWS BETWEEN 4 PRECEDING AND CURRENT ROW), 2) AS "Avg_Games",
    ROUND(AVG(Wins) OVER (ORDER BY year ROWS BETWEEN 4 PRECEDING AND CURRENT ROW), 2) AS "Avg_Wins",
    ROUND(AVG(Draws) OVER (ORDER BY year ROWS BETWEEN 4 PRECEDING AND CURRENT ROW), 2) AS "Avg_Draws",
    ROUND(AVG(Losses) OVER (ORDER BY year ROWS BETWEEN 4 PRECEDING AND CURRENT ROW), 2) AS "Avg_Losses",
    ROUND(AVG(Goals_scored) OVER (ORDER BY year ROWS BETWEEN 4 PRECEDING AND CURRENT ROW), 2) AS "Avg_Goals_Scored",
    ROUND(AVG(Goals_conceded) OVER (ORDER BY year ROWS BETWEEN 4 PRECEDING AND CURRENT ROW), 2) AS "Avg_Goals_Conceded",
    
    -- 5-Year Rolling Win Rate (Sum of Wins / Sum of Games over 5 years)
    ROUND(
        (SUM(Wins) OVER (ORDER BY year ROWS BETWEEN 4 PRECEDING AND CURRENT ROW)::NUMERIC / 
         SUM(total_games) OVER (ORDER BY year ROWS BETWEEN 4 PRECEDING AND CURRENT ROW)) * 100, 
        2
    ) AS "5Yr_Win_Rate_Pct"

FROM portugal_stats
ORDER BY year ASC;

-- ============================================================
--  ERA DEFINITIONS
--  All breakpoints are derived from the C0 rolling 5-year
--  output. Key columns: 5Yr_Win_Rate_Pct and Avg_Goals_Conceded.
--
--  ERA 1 - Struggle Years (1921–1960)
--    Win rate never sustainably exceeded 45% in this period.
--    Hit an all-time low of 5.88% in the 1954 window.
--    Goals conceded averaged 8–11 per 5-year window.
--    Portugal did not qualify for a single World Cup.
--
--  ERA 2 - The Eusébio Era (1961–1974)
--    The clearest breakpoint in the entire dataset.
--    5Yr_Win_Rate jumps from 28.57% (1962) to 57.58% (1966)
--    in just four years — the sharpest rise in the data.
--    Avg_Goals_Conceded drops from 8.40 to 8.00 then 7.20
--    as the team becomes more defensively organised.
--    Peak window: 1967–1968 at 58.82% and 57.14% WR.
--    Decline is visible from 1971 (27.27%) — the post-1966
--    generation was fading. Era ends at 1974: last window
--    with Eusébio-era players as the core of the squad.
--
--  ERA 3 - The Rebuilding Years (1975–1993)
--    Win rate stabilises between 38% and 52% — better than
--    Era 1 but no consistent elite performance.
--    Avg_Goals_Conceded rises again to 10–12 range in the
--    early 1980s, reflecting defensive fragility.
--    The 5Yr_Win_Rate never breaks 52% across this entire
--    19-year period. No World Cup between 1966 and 1986.
--
--  ERA 4 - The Golden Generation (1994–2010)
--    Second major breakpoint: 5Yr_Win_Rate crosses 60% for
--    the first time ever in the 2000 window (60.42%).
--    Peaks at 65.22% in 2001 — the highest to that point.
--    Avg_Goals_Conceded drops sharply: from 6.40 (1993)
--    to 4.60 (1994) and holds below 6.00 through this era.
--    Figo and CR7 coexisted 2003–2006 (overlap period).
--    Win rate starts softening after 2004 (58.73%) as the
--    Golden Generation ages and transitions to Era 5.
--
--  ERA 5 — The Modern Era (2011–2026)
--    Win rate re-accelerates from 2017 onwards: 63.64%,
--    59.42%, 61.19%, 60.00% — consistently above 59%.
--    Recent windows reach new all-time highs:
--    68.97% (2023), 65.63% (2024), 67.31% (2026).
--    Avg_Goals_Conceded holds at 7–11 range — higher than
--    Era 4 peak but offset by dramatically more goals scored
--    (Avg_Goals_Scored rises from ~23 to 30–32 per window).
--    Portugal wins Euro 2016 and UEFA Nations League
--    in this period — the best trophy record in history.
-- ============================================================


-- ------------------------------------------------------------
--  C1 — Portugal's Core Record Per Era
--  Matches, wins, draws, losses, win rate %,
--  goals scored per game, goals conceded per game.
-- ------------------------------------------------------------

WITH era_classification AS (
    SELECT
        *,
        CASE
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1921 AND 1960 THEN '1 - Struggle Years'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1961 AND 1974 THEN '2 - The Eusebio Era'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1975 AND 1993 THEN '3 - The Rebuilding Years'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1994 AND 2010 THEN '4 - The Golden Generation'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 2011 AND 2026 THEN '5 - Modern Era'
        END AS era
    FROM results
    WHERE home_team = 'Portugal' OR away_team = 'Portugal'
), 
core_era AS (
    SELECT
	era,
	COUNT(*) AS Matches_played,
	SUM(CASE WHEN (home_team = 'Portugal' AND home_score > away_score) OR 
		(away_team = 'Portugal' AND home_score < away_score) THEN 1 ELSE 0 END) AS Wins,
	SUM(CASE WHEN home_score = away_score THEN 1 ELSE 0 END) AS Draws,
	SUM(CASE WHEN (home_team = 'Portugal' AND home_score < away_score) OR 
		(away_team = 'Portugal' AND home_score > away_score) THEN 1 ELSE 0 END) AS Losses,
	SUM(CASE WHEN home_team = 'Portugal' THEN home_score
		WHEN away_team = 'Portugal' THEN away_score ELSE 0 END) AS Goals_scored,
	SUM(CASE WHEN home_team = 'Portugal' THEN away_score
		WHEN away_team = 'Portugal' THEN home_score ELSE 0 END) AS Goals_conceded
FROM era_classification
GROUP BY era

)
SELECT
    era,
    Matches_played,
    Wins,
    Draws,
    Losses,
    Goals_scored,
    Goals_conceded,
    ROUND((Wins::NUMERIC / Matches_played) * 100, 2) AS Win_Rate_Percent,
    ROUND((Goals_scored::NUMERIC / Matches_played), 2) AS Avg_Goals_Scored_Per_Match,
    ROUND((Goals_conceded::NUMERIC / Matches_played), 2) AS Avg_Goals_Conceded_Per_Match
FROM core_era
ORDER BY 
    CASE era
        WHEN '1 - Struggle Years' THEN 1
        WHEN '2 - The Eusebio Era' THEN 2
        WHEN '3 - The Rebuilding Years' THEN 3
        WHEN '4 - The Golden Generation' THEN 4
        WHEN '5 - Modern Era' THEN 5
    END;

-- C1 FINDINGS: Win rate grows consistently across eras.
-- Era 1 (29.13%) → Era 5 (60.73%) — more than doubled over 100 years.
-- Most dramatic single-era improvement: Era 1 to Era 4 (+28pp).

-- Goals conceded tells the clearest story: drops from 2.24 to 0.78
-- between Era 1 and Era 4 — defensive solidity is the key driver
-- of Portugal's rise, not just attacking output.


-- ------------------------------------------------------------
--  C2 — Competitive Matches Only Per Era
--  Same as C1 but excluding friendlies.
-- ------------------------------------------------------------

WITH era_classification AS (
    SELECT
        *,
        CASE
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1921 AND 1960 THEN '1 - Struggle Years'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1961 AND 1974 THEN '2 - The Eusebio Era'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1975 AND 1993 THEN '3 - The Rebuilding Years'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1994 AND 2010 THEN '4 - The Golden Generation'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 2011 AND 2026 THEN '5 - Modern Era'
        END AS era
    FROM results
    WHERE (home_team = 'Portugal' OR away_team = 'Portugal') AND tournament <> 'Friendly'
), 
core_era AS (
    SELECT
	era,
	COUNT(*) AS Matches_played,
	SUM(CASE WHEN (home_team = 'Portugal' AND home_score > away_score) OR 
		(away_team = 'Portugal' AND home_score < away_score) THEN 1 ELSE 0 END) AS Wins,
	SUM(CASE WHEN home_score = away_score THEN 1 ELSE 0 END) AS Draws,
	SUM(CASE WHEN (home_team = 'Portugal' AND home_score < away_score) OR 
		(away_team = 'Portugal' AND home_score > away_score) THEN 1 ELSE 0 END) AS Losses,
	SUM(CASE WHEN home_team = 'Portugal' THEN home_score
		WHEN away_team = 'Portugal' THEN away_score ELSE 0 END) AS Goals_scored,
	SUM(CASE WHEN home_team = 'Portugal' THEN away_score
		WHEN away_team = 'Portugal' THEN home_score ELSE 0 END) AS Goals_conceded
FROM era_classification
GROUP BY era

)
SELECT
    era,
    Matches_played,
    Wins,
    Draws,
    Losses,
    Goals_scored,
    Goals_conceded,
    ROUND((Wins::NUMERIC / Matches_played) * 100, 2) AS Win_Rate_Percent,
    ROUND((Goals_scored::NUMERIC / Matches_played), 2) AS Avg_Goals_Scored_Per_Match,
    ROUND((Goals_conceded::NUMERIC / Matches_played), 2) AS Avg_Goals_Conceded_Per_Match
FROM core_era
ORDER BY 
    CASE era
        WHEN '1 - Struggle Years' THEN 1
        WHEN '2 - The Eusebio Era' THEN 2
        WHEN '3 - The Rebuilding Years' THEN 3
        WHEN '4 - The Golden Generation' THEN 4
        WHEN '5 - Modern Era' THEN 5
    END;

-- C2 FINDINGS: Competitive win rates are consistently higher than
-- overall rates across all eras — Portugal performs better when
-- it matters. Gap is largest in Era 1 (29.13% all vs 33.33% comp)
-- and Era 3 (43.94% vs 49.41%), suggesting friendly results
-- drag down the overall numbers in those periods.

-- Era 5 competitive win rate (64.71%) is the highest in history.


-- ------------------------------------------------------------
--  C3 — World Cup Record Per Era
-- ------------------------------------------------------------

WITH era_classification AS (
    SELECT
        *,
        CASE
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1921 AND 1960 THEN '1 - Struggle Years'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1961 AND 1974 THEN '2 - The Eusebio Era'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1975 AND 1993 THEN '3 - The Rebuilding Years'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1994 AND 2010 THEN '4 - The Golden Generation'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 2011 AND 2026 THEN '5 - Modern Era'
        END AS era,
		EXTRACT(YEAR FROM date) AS year
    FROM results
    WHERE (home_team = 'Portugal' OR away_team = 'Portugal') AND tournament = 'FIFA World Cup'
), 
core_era AS (
    SELECT
	era,
	year,
	COUNT(*) AS Matches_played,
	SUM(CASE WHEN (home_team = 'Portugal' AND home_score > away_score) OR 
		(away_team = 'Portugal' AND home_score < away_score) THEN 1 ELSE 0 END) AS Wins,
	SUM(CASE WHEN home_score = away_score THEN 1 ELSE 0 END) AS Draws,
	SUM(CASE WHEN (home_team = 'Portugal' AND home_score < away_score) OR 
		(away_team = 'Portugal' AND home_score > away_score) THEN 1 ELSE 0 END) AS Losses,
	SUM(CASE WHEN home_team = 'Portugal' THEN home_score
		WHEN away_team = 'Portugal' THEN away_score ELSE 0 END) AS Goals_scored,
	SUM(CASE WHEN home_team = 'Portugal' THEN away_score
		WHEN away_team = 'Portugal' THEN home_score ELSE 0 END) AS Goals_conceded
FROM era_classification
GROUP BY era, year

)
SELECT
    era,
	year,
    Matches_played,
    Wins,
    Draws,
    Losses,
    Goals_scored,
    Goals_conceded,
    ROUND((Wins::NUMERIC / Matches_played) * 100, 2) AS Win_Rate_Percent,
    ROUND((Goals_scored::NUMERIC / Matches_played), 2) AS Avg_Goals_Scored_Per_Match,
    ROUND((Goals_conceded::NUMERIC / Matches_played), 2) AS Avg_Goals_Conceded_Per_Match
FROM core_era
ORDER BY 
    CASE era
        WHEN '1 - Struggle Years' THEN 1
        WHEN '2 - The Eusebio Era' THEN 2
        WHEN '3 - The Rebuilding Years' THEN 3
        WHEN '4 - The Golden Generation' THEN 4
        WHEN '5 - Modern Era' THEN 5
    END;

-- C3 FINDINGS: Portugal appeared in 8 World Cups total.
-- Best campaign: 1966 — 83.33% WR, 3rd place (Era 2, Eusébio).

-- Era 1 (1921–1960): 0 World Cup appearances out of 6 editions
-- (1930–1958) — Portugal failed to qualify for all of them.

-- Era 3 only produced 1 appearance (1986) from 4 possible editions.

-- Era 4 and Era 5 combined for 7 appearances — consistent qualification
-- became the norm from 2002 onwards.

-- NOTE: World Cup began in 1930. Era 1 had 6 editions available
-- (1930, 1934, 1938, 1950, 1954, 1958) — Portugal missed all 6.


-- ------------------------------------------------------------
--  C4 — UEFA Euro Record Per Era
-- ------------------------------------------------------------

WITH era_classification AS (
    SELECT
        *,
        CASE
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1921 AND 1960 THEN '1 - The  Difficult Years' 
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1961 AND 1974 THEN '2 - The Eusebio Era'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1975 AND 1993 THEN '3 - The Rebuilding Years'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1994 AND 2010 THEN '4 - The Golden Generation'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 2011 AND 2026 THEN '5 - Modern Era'
        END AS era,
		EXTRACT(YEAR FROM date) AS year
    FROM results
    WHERE (home_team = 'Portugal' OR away_team = 'Portugal') AND tournament = 'UEFA Euro'
), 
core_era AS (
    SELECT
	era,
	year,
	COUNT(*) AS Matches_played,
	SUM(CASE WHEN (home_team = 'Portugal' AND home_score > away_score) OR 
		(away_team = 'Portugal' AND home_score < away_score) THEN 1 ELSE 0 END) AS Wins,
	SUM(CASE WHEN home_score = away_score THEN 1 ELSE 0 END) AS Draws,
	SUM(CASE WHEN (home_team = 'Portugal' AND home_score < away_score) OR 
		(away_team = 'Portugal' AND home_score > away_score) THEN 1 ELSE 0 END) AS Losses,
	SUM(CASE WHEN home_team = 'Portugal' THEN home_score
		WHEN away_team = 'Portugal' THEN away_score ELSE 0 END) AS Goals_scored,
	SUM(CASE WHEN home_team = 'Portugal' THEN away_score
		WHEN away_team = 'Portugal' THEN home_score ELSE 0 END) AS Goals_conceded
FROM era_classification
GROUP BY era, year
)

SELECT
    era,
	year,
    Matches_played,
    Wins,
    Draws,
    Losses,
    Goals_scored,
    Goals_conceded,
    ROUND((Wins::NUMERIC / Matches_played) * 100, 2) AS Win_Rate_Percent,
    ROUND((Goals_scored::NUMERIC / Matches_played), 2) AS Avg_Goals_Scored_Per_Match,
    ROUND((Goals_conceded::NUMERIC / Matches_played), 2) AS Avg_Goals_Conceded_Per_Match
FROM core_era
ORDER BY 
    CASE era
        WHEN '1 - Struggle Years' THEN 1
        WHEN '2 - The Eusebio Era' THEN 2
        WHEN '3 - The Rebuilding Years' THEN 3
        WHEN '4 - The Golden Generation' THEN 4
        WHEN '5 - Modern Era' THEN 5
    END;

-- C4 FINDINGS: Portugal appeared in 9 Euros total.
-- "Best campaign": Euro 2000 — 80.00% WR, semi-final (Era 4).

-- Euro 2016 is deceptive: 42.86% WR but Portugal won the tournament
-- (4 draws in 90 minutes, won every knockout on minimal margins).

-- NOTE: UEFA Euro began in 1960. Era 1 had 0 editions available.
-- Era 2 had 3 editions (1960, 1964, 1968) — Portugal missed all 3.
-- Era 3 reached the first ever Euro appearance (1984).


-- ------------------------------------------------------------
--  C5 — Best to Worst Tournament Campaigns
--  Which individual World Cup or Euro edition produced
--  Portugal's best and worst results (based of win rate)?
-- ------------------------------------------------------------

WITH era_classification AS (
    SELECT
        *,
        CASE
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1921 AND 1960 THEN '1 - Struggle Years'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1961 AND 1974 THEN '2 - The Eusebio Era'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1975 AND 1993 THEN '3 - The Rebuilding Years'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1994 AND 2010 THEN '4 - The Golden Generation'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 2011 AND 2026 THEN '5 - Modern Era'
        END AS era,
		EXTRACT(YEAR FROM date) AS year
    FROM results
    WHERE (home_team = 'Portugal' OR away_team = 'Portugal') 
		AND (tournament = 'UEFA Euro' OR tournament = 'FIFA World Cup')
), 
core_era AS (
    SELECT
	era,
	year,
	COUNT(*) AS Matches_played,
	SUM(CASE WHEN (home_team = 'Portugal' AND home_score > away_score) OR 
		(away_team = 'Portugal' AND home_score < away_score) THEN 1 ELSE 0 END) AS Wins,
	SUM(CASE WHEN home_score = away_score THEN 1 ELSE 0 END) AS Draws,
	SUM(CASE WHEN (home_team = 'Portugal' AND home_score < away_score) OR 
		(away_team = 'Portugal' AND home_score > away_score) THEN 1 ELSE 0 END) AS Losses,
	SUM(CASE WHEN home_team = 'Portugal' THEN home_score
		WHEN away_team = 'Portugal' THEN away_score ELSE 0 END) AS Goals_scored,
	SUM(CASE WHEN home_team = 'Portugal' THEN away_score
		WHEN away_team = 'Portugal' THEN home_score ELSE 0 END) AS Goals_conceded
FROM era_classification
GROUP BY era, year

)
SELECT
    year,
	era,
	CASE 
    	WHEN year IN (SELECT DISTINCT EXTRACT(YEAR FROM date) AS year FROM results WHERE tournament = 'FIFA World Cup') 
		THEN 'Fifa World Cup'
    	ELSE 'UEFA Euro' 
	END AS tournament_type,
    Matches_played,
    Wins,
    Draws,
    Losses,
    Goals_scored,
    Goals_conceded,
    ROUND((Wins::NUMERIC / Matches_played) * 100, 2) AS Win_Rate_Percent,
    ROUND((Goals_scored::NUMERIC / Matches_played), 2) AS Avg_Goals_Scored_Per_Match,
    ROUND((Goals_conceded::NUMERIC / Matches_played), 2) AS Avg_Goals_Conceded_Per_Match
FROM core_era
ORDER BY Win_Rate_Percent DESC;

-- C5 FINDINGS: 1966 World Cup is the undisputed best
-- campaign (83.33% WR, 6 goals/game ratio of 2.83).

-- Euro 2000 is the best non-Eusébio campaign (80.00% WR).

-- Worst campaigns cluster in Era 3 and early Era 5:
-- 1984 Euro and 2010/2018/2021 all at 25.00% WR.
-- 2010 World Cup stands out: only 1 goal conceded in 4 games
-- (0.25 GA/game) despite a 25% WR — extremely defensive campaign.


-- ------------------------------------------------------------
--  C6 — Top Scorers Per Era
--  Portugal's leading goalscorers in each era.
-- ------------------------------------------------------------

WITH era_classification AS (
    SELECT
        *,
        CASE
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1921 AND 1960 THEN '1 - Struggle Years'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1961 AND 1974 THEN '2 - The Eusebio Era'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1975 AND 1993 THEN '3 - The Rebuilding Years'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1994 AND 2010 THEN '4 - The Golden Generation'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 2011 AND 2026 THEN '5 - Modern Era'
        END AS era
    FROM goalscorers
    WHERE team = 'Portugal' AND own_goal = FALSE
), 
ranked_scorers AS (
    SELECT
        era,
        scorer,
        COUNT(*) AS goals_count,
        RANK() OVER (PARTITION BY era ORDER BY COUNT(*) DESC) AS rank
    FROM era_classification
    GROUP BY era, scorer
)
SELECT
    era,
    scorer,
    goals_count,
    rank
FROM ranked_scorers
WHERE rank <= 5
ORDER BY era, rank;

-- C6 FINDINGS: CR7 dominates Era 5 with 99 goals —
-- nearly 5x the next scorer (Bruno Fernandes, 19).

-- In Era 4, CR7 scored 22 goals — already 2nd in that era behind
-- Pauleta (25), confirming his emergence during the Golden Generation.

-- Eusébio's 26 goals in Era 2 are underrepresented — FPF official
-- record is 41 goals. Dataset coverage gap confirmed for pre-1968.
-- Era 1 top scorer (Vítor Silva, 4 goals) reflects how rarely
-- individual players dominated in that period.


-- ------------------------------------------------------------
--  C7 — First Half vs Second Half Goals Per Era
--  Split Portugal's goals at minute 45.
-- ------------------------------------------------------------

WITH goals_by_half AS (
    SELECT
        CASE
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1921 AND 1960 THEN '1 - Struggle Years'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1961 AND 1974 THEN '2 - The Eusebio Era'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1975 AND 1993 THEN '3 - The Rebuilding Years'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 1994 AND 2010 THEN '4 - The Golden Generation'
            WHEN EXTRACT(YEAR FROM date) BETWEEN 2011 AND 2026 THEN '5 - Modern Era'
        END AS era,
        CASE
            WHEN CAST(minute AS INTEGER) <= 45 THEN 'First Half' 
            WHEN CAST(minute AS INTEGER) BETWEEN 46 AND 90 THEN 'Second Half'
            ELSE 'Extra Time' 
        END AS half,
        COUNT(*) AS goals
    FROM goalscorers
    WHERE team = 'Portugal' 
        AND own_goal = FALSE
        AND minute IS NOT NULL 
        AND minute NOT LIKE '%+%'
    GROUP BY era, half
),
stats_by_era AS (
    SELECT
        era,
        SUM(goals) FILTER (WHERE half = 'First Half') AS goals_1st_half,
        SUM(goals) FILTER (WHERE half = 'Second Half') AS goals_2nd_half,
        SUM(goals) FILTER (WHERE half = 'Extra Time') AS goals_extra_time,
        (SUM(goals) FILTER (WHERE half = 'Second Half') - SUM(goals) FILTER (WHERE half = 'First Half')) AS diff_2nd_minus_1st
    FROM goals_by_half
    GROUP BY era
)
SELECT
    era,
    goals_1st_half,
    goals_2nd_half,
    goals_extra_time,
    diff_2nd_minus_1st AS "Difference (2nd - 1st)",
    CASE 
        WHEN diff_2nd_minus_1st > 0 THEN 'More goals in 2nd Half'
        WHEN diff_2nd_minus_1st < 0 THEN 'More goals in 1st Half'
        ELSE 'Equal'
    END AS analysis
FROM stats_by_era
ORDER BY 
    CASE era
        WHEN '1 - Struggle Years' THEN 1
        WHEN '2 - The Eusebio Era' THEN 2
        WHEN '3 - The Rebuilding Years' THEN 3
        WHEN '4 - The Golden Generation' THEN 4
        WHEN '5 - Modern Era' THEN 5
    END;

-- C7 FINDINGS: Portugal consistently scores more
-- in the second half across all eras — the gap grows with each era.

-- Era 4 and Era 5 both show a 47-goal difference (2nd vs 1st half).
-- This likely reflects both fitness levels and tactical adjustments
-- at half-time becoming more sophisticated in the modern game.


-- ------------------------------------------------------------
--  C8 — Penalty Goals Per Era
--  How many of Portugal's goals came from the penalty spot?
-- ------------------------------------------------------------

SELECT
	CASE
		WHEN EXTRACT(YEAR FROM date) BETWEEN 1921 AND 1960 THEN '1 - Struggle Years'
		WHEN EXTRACT(YEAR FROM date) BETWEEN 1961 AND 1974 THEN '2 - The Eusebio Era'
		WHEN EXTRACT(YEAR FROM date) BETWEEN 1975 AND 1993 THEN '3 - The Rebuilding Years'
		WHEN EXTRACT(YEAR FROM date) BETWEEN 1994 AND 2010 THEN '4 - The Golden Generation'
		WHEN EXTRACT(YEAR FROM date) BETWEEN 2011 AND 2026 THEN '5 - Modern Era'
	END AS era,
	COUNT(*) as penalty_goals
FROM goalscorers
WHERE team = 'Portugal' and penalty = TRUE
GROUP BY era

-- C8 FINDINGS: Penalty goals grow dramatically in Era 5
-- (24 goals) vs Era 4 (8 goals) — partly CR7's influence, partly
-- the increased number of competitive matches played.
-- Era 1 had just 1 penalty goal across 103 matches.


-- ------------------------------------------------------------
--  C9 — Biggest Wins Per Era
--  Top 3 largest winning margins per era.
-- ------------------------------------------------------------

WITH era_classification AS (
    SELECT
        *,
        CASE
			WHEN EXTRACT(YEAR FROM date) BETWEEN 1921 AND 1960 THEN '1 - Struggle Years'
			WHEN EXTRACT(YEAR FROM date) BETWEEN 1961 AND 1974 THEN '2 - The Eusebio Era'
			WHEN EXTRACT(YEAR FROM date) BETWEEN 1975 AND 1993 THEN '3 - The Rebuilding Years'
			WHEN EXTRACT(YEAR FROM date) BETWEEN 1994 AND 2010 THEN '4 - The Golden Generation'
			WHEN EXTRACT(YEAR FROM date) BETWEEN 2011 AND 2026 THEN '5 - Modern Era'
        END AS era
    FROM results
    WHERE home_team = 'Portugal'
       OR away_team = 'Portugal'
),
wins_with_margin AS (
    SELECT
        era,
        date,
        home_team,
        away_team,
        home_score,
        away_score,
        tournament,
        CASE
            WHEN home_team = 'Portugal' THEN home_score - away_score
            ELSE away_score - home_score
        END AS winning_margin
    FROM era_classification
    WHERE (home_team = 'Portugal' AND home_score > away_score)
       OR (away_team = 'Portugal' AND away_score > home_score)
),
ranked AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY era ORDER BY winning_margin DESC) AS rank
    FROM wins_with_margin
)
SELECT
    era,
    rank,
    date,
    home_team,
    away_team,
    home_score,
    away_score,
    winning_margin,
    tournament
FROM ranked
WHERE rank <= 3
ORDER BY era, rank;

-- C9 FINDINGS: Portugal's biggest wins grow in margin
-- across eras — from 4-goal margins in Era 1 to 9-goal margins in Era 5.
-- Era 4 produced three 8-0 victories (vs Liechtenstein x2, Kuwait).

-- Notable: Era 2's biggest win was 6-0 vs Luxembourg in WC qualification
-- (1961) — a sign of Eusébio-era dominance even in early matches.
-- Era 5 peak: 9-0 vs Luxembourg (2023, Euro 2024 qualification).


-- ------------------------------------------------------------
--  C10 — Biggest Defeats Per Era
--  Top 3 largest losing margins per era.
-- ------------------------------------------------------------

WITH era_classification AS (
    SELECT
        *,
        CASE
			WHEN EXTRACT(YEAR FROM date) BETWEEN 1921 AND 1960 THEN '1 - Struggle Years'
			WHEN EXTRACT(YEAR FROM date) BETWEEN 1961 AND 1974 THEN '2 - The Eusebio Era'
			WHEN EXTRACT(YEAR FROM date) BETWEEN 1975 AND 1993 THEN '3 - The Rebuilding Years'
			WHEN EXTRACT(YEAR FROM date) BETWEEN 1994 AND 2010 THEN '4 - The Golden Generation'
			WHEN EXTRACT(YEAR FROM date) BETWEEN 2011 AND 2026 THEN '5 - Modern Era'
        END AS era
    FROM results
    WHERE home_team = 'Portugal'
       OR away_team = 'Portugal'
),
losses_with_margin AS (
    SELECT
        era,
        date,
        home_team,
        away_team,
        home_score,
        away_score,
        tournament,
        CASE
            WHEN home_team = 'Portugal' THEN away_score - home_score
            ELSE home_score - away_score
        END AS losing_margin
    FROM era_classification
    WHERE (home_team = 'Portugal' AND home_score < away_score)
       OR (away_team = 'Portugal' AND away_score < home_score)
),
ranked AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY era ORDER BY losing_margin DESC) AS rank
    FROM losses_with_margin
)
SELECT
    era,
    rank,
    date,
    home_team,
    away_team,
    home_score,
    away_score,
    losing_margin,
    tournament
FROM ranked
WHERE rank <= 3
ORDER BY era, rank;

-- C10 FINDINGS: The severity of defeats decreases
-- dramatically across eras — from 10-goal losses (Era 1) to 4-goal
-- losses (Era 5, and that was Germany at the 2014 World Cup).

-- Era 1 worst: 0-10 vs England (1947, Friendly) — the heaviest
-- defeat in Portugal's entire history.

-- Era 2 biggest defeats were only 3-goal margins — a massive
-- improvement, confirming Eusébio era defensive organisation.

-- Modern era (Era 5) worst competitive loss: 4-0 vs Germany
-- at the 2014 World Cup group stage. 
-- This 4-goal margin is a significant outlier for Era 5. 
-- The second worst loss in this entire era was 3-0 against 
-- the Netherlands in a friendly. 
-- However, beyond those two results, all other defeats 
-- in the Modern Era were lost by a margin of exactly 2 goals or less.
-- This confirms that aside from the Germany dominance a team that also
-- trashed hosts Brazil 7-1 in that World Cup, Portugal has 
-- become extremely resilient and avoids heavy "blowouts" in the modern period.


-- ------------------------------------------------------------
--  C11 — Era Scorecard: All Key Metrics Side by Side
-- ------------------------------------------------------------


WITH era_classification AS (
    SELECT
        *,
        CASE
			WHEN EXTRACT(YEAR FROM date) BETWEEN 1921 AND 1960 THEN '1 - Struggle Years'
			WHEN EXTRACT(YEAR FROM date) BETWEEN 1961 AND 1974 THEN '2 - The Eusebio Era'
			WHEN EXTRACT(YEAR FROM date) BETWEEN 1975 AND 1993 THEN '3 - The Rebuilding Years'
			WHEN EXTRACT(YEAR FROM date) BETWEEN 1994 AND 2010 THEN '4 - The Golden Generation'
			WHEN EXTRACT(YEAR FROM date) BETWEEN 2011 AND 2026 THEN '5 - Modern Era'
        END AS era
    FROM results
    WHERE home_team = 'Portugal'
       OR away_team = 'Portugal'
),

-- All matches metrics
base_metrics AS (
    SELECT
        era,
        COUNT(*) AS total_matches,
        SUM(CASE
            WHEN home_team = 'Portugal' AND home_score > away_score THEN 1
            WHEN away_team = 'Portugal' AND away_score > home_score THEN 1
            ELSE 0 END) AS wins,
        ROUND(
            SUM(CASE
                WHEN home_team = 'Portugal' AND home_score > away_score THEN 1
                WHEN away_team = 'Portugal' AND away_score > home_score THEN 1
                ELSE 0 END)::NUMERIC / COUNT(*) * 100, 2) AS win_rate_pct,
        ROUND(AVG(CASE
            WHEN home_team = 'Portugal' THEN home_score
            ELSE away_score END), 2) AS avg_goals_scored,
        ROUND(AVG(CASE
            WHEN home_team = 'Portugal' THEN away_score
            ELSE home_score END), 2) AS avg_goals_conceded
    FROM era_classification
    GROUP BY era
),

-- Competitive matches only
competitive_metrics AS (
    SELECT
        era,
        COUNT(*) AS competitive_matches,
        ROUND(
            SUM(CASE
                WHEN home_team = 'Portugal' AND home_score > away_score THEN 1
                WHEN away_team = 'Portugal' AND away_score > home_score THEN 1
                ELSE 0 END)::NUMERIC / COUNT(*) * 100, 2) AS competitive_win_rate_pct
    FROM era_classification
    WHERE tournament != 'Friendly'
    GROUP BY era
),

-- Major tournament appearances
tournament_metrics AS (
    SELECT
        era,
        COUNT(DISTINCT EXTRACT(YEAR FROM date))                        AS major_tournament_editions,
        COUNT(*)                                                        AS major_tournament_matches
    FROM era_classification
    WHERE tournament IN ('FIFA World Cup', 'UEFA Euro')
    GROUP BY era
),

-- Shootout record
shootout_metrics AS (
    SELECT
        CASE
			WHEN EXTRACT(YEAR FROM date) BETWEEN 1921 AND 1960 THEN '1 - Struggle Years'
			WHEN EXTRACT(YEAR FROM date) BETWEEN 1961 AND 1974 THEN '2 - The Eusebio Era'
			WHEN EXTRACT(YEAR FROM date) BETWEEN 1975 AND 1993 THEN '3 - The Rebuilding Years'
			WHEN EXTRACT(YEAR FROM date) BETWEEN 1994 AND 2010 THEN '4 - The Golden Generation'
			WHEN EXTRACT(YEAR FROM date) BETWEEN 2011 AND 2026 THEN '5 - Modern Era'
        END AS era,
        COUNT(*) AS shootouts_total,
        SUM(CASE WHEN winner = 'Portugal' THEN 1 ELSE 0 END) AS shootouts_won
    FROM shootouts
    WHERE home_team = 'Portugal'
       OR away_team = 'Portugal'
    GROUP BY era
)

-- Final scorecard
SELECT
    b.era,
    b.total_matches,
    b.win_rate_pct,
    c.competitive_win_rate_pct,
    b.avg_goals_scored,
    b.avg_goals_conceded,
    COALESCE(t.major_tournament_editions, 0) AS major_tournament_editions,
    COALESCE(t.major_tournament_matches, 0) AS major_tournament_matches,
    COALESCE(s.shootouts_won, 0) || '/' || COALESCE(s.shootouts_total, 0) AS shootout_record
	
FROM base_metrics b
LEFT JOIN competitive_metrics c ON b.era = c.era
LEFT JOIN tournament_metrics t ON b.era = t.era
LEFT JOIN shootout_metrics s ON b.era = s.era
ORDER BY b.era;

-- C11 FINDINGS: Era 4 and Era 5 are the standout eras
-- by almost every metric. Key differentiators:
-- Goals conceded: Era 4 (0.78) edges Era 5 (0.83) — Era 4 was
-- more defensively solid despite similar win rates.

-- Shootouts: Era 4 went 2/2, Era 5 went 3/6 — Era 4 perfect
-- record but small sample; Era 5 has more data.
-- Major tournaments: Era 4 and Era 5 tied at 7 editions each —
-- consistent presence at the highest level from 1994 onwards.

-- SHOOTOUT INTEGRITY CHECK:
-- Penalty shootouts were introduced in 1970. Portugal's first
-- appearance was in 2004 — confirming Era 1, 2 and 3 show 0/0 correctly.
-- Era 4: 2W 0L (Euro 2004, WC 2006)
-- Era 5: 3W 3L (Euro 2012, Confed. 2017, Euro 2024 x2, NL 2025, Euro 2024)

-- Era 3 only reached 2 major tournament editions despite 19 years.
-- Era 1 reached zero — 39 years of international football with
-- no World Cup or Euro participation.



-- ============================================================
--  ERA ANALYSIS SUMMARY
--
--  693 Portugal matches analysed across 5 defined eras.
--
--  THE STORY IN DATA:
--
--  Era 1 — Struggle Years (1921–1960)
--  The foundation period. 29% win rate, 2.24 goals conceded
--  per game, zero major tournament appearances across 39 years.
--  Heaviest defeat in history: 0-10 vs England (1947).
--
--  Era 2 — The Eusébio Era (1961–1974)
--  The first transformation. Win rate jumps to 44.87% and
--  goals conceded drops to 1.15 — the sharpest single-era
--  defensive improvement in the dataset. One World Cup
--  appearance, finishing 3rd in 1966 with 83.33% WR.
--  Biggest defeats in this era were only 3-goal margins.
--
--  Era 3 — The Rebuilding Years (1975–1993)
--  A plateau, not a decline. Win rate holds at 43.94% —
--  similar to Era 2 but no breakthrough. Only 2 major
--  tournament appearances in 19 years. The data shows
--  a team rebuilding without a defining generation.
--
--  Era 4 — The Golden Generation (1994–2010)
--  The second transformation — and arguably the strongest
--  era defensively. Win rate reaches 57.14%, goals conceded
--  drops to a historic low of 0.78/game. 7 major tournament
--  editions, perfect shootout record (2/2). Euro 2000 was
--  the peak campaign (80% WR). CR7 emerges here as 2nd
--  top scorer (22 goals) behind Pauleta (25).
--
--  Era 5 — The Modern Era (2011–2026)
--  The highest win rate in history (60.73% overall,
--  64.71% competitive). Goals scored peak at 2.12/game.
--  CR7 scores 99 goals — nearly 5x the next player.
--  Euro 2016 and 2 Nations League titles. However, goals
--  conceded (0.83) is slightly worse than Era 4 — the
--  team is more attacking but marginally less defensively
--  dominant. Shootout record (3/6) reveals vulnerability
--  under pressure compared to Era 4's perfect 2/2.
--
--  CENTRAL QUESTION ANSWER:
--  By win rate and trophy record: Era 5 (The Modern Era).
--  By defensive solidity and tournament consistency: Era 4.
--  By historical impact and transformation: Era 2.
--  The data does not produce a single clear winner —
--  which is itself the most honest and interesting finding.
--
--  Next: 05_analysis_advanced.sql
--  Unbeaten runs, comeback wins, shootout deep-dive.
-- ============================================================