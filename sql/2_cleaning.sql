-- ============================================================
--  PROJECT  : Football Analytics — Portugal 1921–2026
--  SCRIPT   : 2_cleaning.sql
--  PURPOSE  : Data Cleaning, Quality Audit & Initial Exploration
--  DATABASE : football_analytics
--  AUTHOR   : João Felicíssimo
--  DATE     : June 2026
-- ============================================================


-- ============================================================
--  BLOCK A — DATA QUALITY AUDIT
--  Goal: understand the state of the raw data before any
--  analysis. Identify nulls, duplicates, impossible values,
--  and inconsistencies across all four tables.
-- ============================================================


-- ------------------------------------------------------------
--  A1 — Row Count Verification
-- ------------------------------------------------------------

SELECT COUNT(*)
FROM former_names

UNION ALL

SELECT COUNT(*)
FROM results

UNION ALL

SELECT COUNT(*)
FROM goalscorers

UNION ALL

SELECT COUNT(*)
FROM shootouts;

-- A1 FINDINGS: All four tables loaded correctly.
-- results=49281 | goalscorers=47601 | shootouts=675 | former_names=36


-- ------------------------------------------------------------
--  A2 — Null Check: results
--  Are there any NULL values in critical columns?
-- ------------------------------------------------------------
SELECT
    COUNT(*) FILTER (WHERE date IS NULL)        AS null_date,
    COUNT(*) FILTER (WHERE home_team IS NULL)   AS null_home_team,
    COUNT(*) FILTER (WHERE away_team IS NULL)   AS null_away_team,
    COUNT(*) FILTER (WHERE home_score IS NULL)  AS null_home_score,
    COUNT(*) FILTER (WHERE away_score IS NULL)  AS null_away_score,
    COUNT(*) FILTER (WHERE tournament IS NULL)  AS null_tournament
FROM results;

-- A2 FINDINGS: No NULL values found in any critical column of results.
-- Dataset is fully populated.

-- ------------------------------------------------------------
--  A3 — Null Check: goalscorers
--  The scorer and minute columns are the most likely
--  to have gaps. How many rows are missing each?
-- ------------------------------------------------------------

SELECT
    COUNT(*) FILTER (WHERE scorer IS NULL)    AS null_scorer,
    COUNT(*) FILTER (WHERE minute IS NULL)    AS null_minute,
    COUNT(*) FILTER (WHERE own_goal IS NULL)  AS null_own_goal,
    COUNT(*) FILTER (WHERE penalty IS NULL)   AS null_penalty
FROM goalscorers;

-- A3 FINDINGS: No NULL values found in goalscorers.
-- Note: 'NA' string values in minute (256 rows) and scorer (48 rows) were
-- detected in A6 and handled separately.

-- ------------------------------------------------------------
--  A4 — Null Check: shootouts
--  first_shooter is nullable — some older records
--  have no data. How many are missing?
-- ------------------------------------------------------------

SELECT
    COUNT(*) FILTER (WHERE winner IS NULL)        AS null_winner,
    COUNT(*) FILTER (WHERE first_shooter IS NULL) AS null_first_shooter
FROM shootouts;

-- A4 FINDINGS: winner has 0 NULLs as expected.
-- first_shooter has 429 NULLs — expected, older records lack this data.
-- No action required.


-- ------------------------------------------------------------
--  A5 — Duplicate Check: results
--  Can the same match appear twice?
-- ------------------------------------------------------------

SELECT date, home_team, away_team, city, country
FROM results
GROUP BY date, home_team, away_team, city, country
HAVING COUNT(*) > 1;

-- A5 FINDINGS: One duplicate match detected.
-- 1974-02-17 | Tahiti vs New Caledonia — likely a data entry issue in source.
-- Does not involve Portugal. No action taken — out of scope.


-- ------------------------------------------------------------
--  A6 — Duplicate Check: goalscorers
--  A duplicate goal record would share the same date,
--  home_team, away_team, team, scorer, and minute.
-- ------------------------------------------------------------

SELECT date, team, scorer, minute, own_goal, penalty
FROM goalscorers
GROUP BY date, team, scorer, minute, own_goal, penalty
HAVING COUNT(*) > 1;

--
-- PROBLEM DETECTED
--

-- Convert string 'NA' to proper NULL in goalscorers
UPDATE goalscorers
SET minute = NULL
WHERE minute = 'NA';

UPDATE goalscorers
SET scorer = NULL
WHERE scorer = 'NA';

SELECT
    COUNT(*) FILTER (WHERE minute IS NULL)  AS na_minute,
    COUNT(*) FILTER (WHERE scorer = 'NA')  AS na_scorer
FROM goalscorers;

-- NOTE: 48 rows in goalscorers have scorer = 'NA' (missing historical data).
-- These records belong to non-Portugal matches and do not affect this project's
-- analysis. No action taken — out of scope.

-- A6 FINDINGS: Apparent duplicates are caused by scorer = 'NA' and minute = 'NA'
-- (string literal, not NULL) in older historical records.
-- minute 'NA' values were converted to NULL (256 rows updated).
-- scorer 'NA' values (48 rows) belong exclusively to non-Portugal matches
-- and were left as-is. See cleaning note above.


-- ------------------------------------------------------------
--  A7 — Impossible Scores: results
--  Are there any matches with negative scores, or where
--  both teams scored 0 in every single game for decades
--  (which would suggest missing data)?
-- ------------------------------------------------------------

SELECT *
FROM results
WHERE home_score < 0 OR away_score < 0 OR
	home_score > 20 OR away_score > 20;

-- A7 FINDINGS: 9 matches with scores above 20 goals detected.
-- All are legitimate outliers (e.g. Australia 31-0 American Samoa, 2001 WC qualification).
-- No impossible or negative scores found. No action required.


-- ------------------------------------------------------------
--  A8 — Date Range Check: results
--  What is the earliest and latest match date in the dataset?
--  Portugal's first match was on 18/12/1921 —
--  does the data confirm this?
-- ------------------------------------------------------------

SELECT *
FROM results
WHERE date = (SELECT MIN(date) AS date FROM results) 
	OR date = (SELECT MAX(date) AS date FROM results)
LIMIT ; -- A lot of matches happened in 2026-05-31, so we limit to just one for simplicity

SELECT *
FROM results
WHERE (date = (SELECT MIN(date) AS date FROM results WHERE home_team = 'Portugal' OR away_team = 'Portugal') 
	OR date = (SELECT MAX(date) AS date FROM results WHERE home_team = 'Portugal' OR away_team = 'Portugal'))
	AND (home_team = 'Portugal' OR away_team = 'Portugal');

-- A8 FINDINGS: Dataset spans 1872-11-30 to 2026-05-31 as expected.
-- Portugal's first match confirmed: 1921-12-18 (Spain 3-1 Portugal, Friendly, Madrid).
-- Portugal's last match in dataset: 2026-03-31 (United States 0-2 Portugal, Friendly).

-- ------------------------------------------------------------
--  A9 — Date Format Issue: shootouts
--  shootouts.date was imported as TEXT because the format
--  is DD/MM/YYYY, unlike the other tables (YYYY-MM-DD).
--  Verify the format is consistent before converting.
-- ------------------------------------------------------------

SELECT LEFT(date, 2), COUNT(*)
FROM shootouts
GROUP BY LEFT(date, 2)
ORDER BY 1; -- Check if date are really in the wrong format


SELECT date, TO_DATE(date, 'DD/MM/YYYY')
FROM shootouts
LIMIT 5;

-- A9 FINDINGS: shootouts.date confirmed in DD/MM/YYYY format.
-- Conversion tested successfully before applying.

-- ------------------------------------------------------------
--  A10 — Fix: Convert shootouts.date to DATE type
--  Now that the format is confirmed, make the conversion
--  permanent by adding a new DATE column, updating it,
--  and dropping the original TEXT column.
-- ------------------------------------------------------------

-- add the new clean column
ALTER TABLE shootouts ADD COLUMN date_clean DATE;

-- populate it
UPDATE shootouts
SET date_clean = TO_DATE(date, 'DD/MM/YYYY');

-- drop the original
ALTER TABLE shootouts DROP COLUMN date;

-- rename
ALTER TABLE shootouts RENAME COLUMN date_clean TO date;

-- check
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'shootouts' AND column_name = 'date';

-- A10 FINDINGS: shootouts.date successfully converted from TEXT (DD/MM/YYYY)
-- to DATE type (YYYY-MM-DD). Column renamed after conversion.



-- ============================================================
--  CLEANING SUMMARY
--
--  All four tables passed quality checks with minor issues.
--
--  CHANGES MADE TO DATA:
--  1. goalscorers.minute — 256 'NA' string values converted to NULL.
--  2. shootouts.date     — column converted from TEXT (DD/MM/YYYY)
--                          to DATE type (YYYY-MM-DD).
--
--  ISSUES DOCUMENTED, NO ACTION TAKEN:
--  1. goalscorers.scorer — 48 'NA' values (non-Portugal matches, out of scope).
--  2. results            — 1 duplicate match (Tahiti vs New Caledonia, 1974,
--                          non-Portugal, out of scope).
--  3. shootouts          — 429 NULL values in first_shooter (expected,
--                          missing historical data).
--  4. results            — 9 matches with scores above 20 goals (legitimate
--                          outliers, not data errors).
--
--  DATASET IS READY FOR EXPLORATION.
--  Next: 3_exploration.sql
-- ============================================================