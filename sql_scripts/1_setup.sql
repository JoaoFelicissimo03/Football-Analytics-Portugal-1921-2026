-- ============================================================
--  Football Analytics 1872-2026
--  Script 1 — Create tables and import data
-- ============================================================
 
 
-- ------------------------------------------------------------
--  Drop tables if they already exist (safe to re-run)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS shootouts;
DROP TABLE IF EXISTS goalscorers;
DROP TABLE IF EXISTS results;
DROP TABLE IF EXISTS former_names;
 
 
-- ------------------------------------------------------------
--  1. results
-- ------------------------------------------------------------
CREATE TABLE results (
    date        DATE         NOT NULL,
    home_team   VARCHAR(50)  NOT NULL,
    away_team   VARCHAR(50)  NOT NULL,
    home_score  SMALLINT     NOT NULL,
    away_score  SMALLINT     NOT NULL,
    tournament  VARCHAR(100) NOT NULL,
    city        VARCHAR(50)  NOT NULL,
    country     VARCHAR(50)  NOT NULL,
    neutral     BOOLEAN      NOT NULL
);
 
COPY results (date, home_team, away_team, home_score, away_score, tournament, city, country, neutral)
FROM 'C:\Users\joaof\Desktop\Projects_db\sql\Football\data\results.csv' -- data path
DELIMITER ','
CSV HEADER;
 
 
-- ------------------------------------------------------------
--  2. goalscorers
--     minute stored as VARCHAR — values like '90+3' exist
-- ------------------------------------------------------------
CREATE TABLE goalscorers (
    date        DATE         NOT NULL,
    home_team   VARCHAR(50)  NOT NULL,
    away_team   VARCHAR(50)  NOT NULL,
    team        VARCHAR(50)  NOT NULL,
    scorer      VARCHAR(100) NOT NULL,
    minute      VARCHAR(10),
    own_goal    BOOLEAN      NOT NULL,
    penalty     BOOLEAN      NOT NULL
);
 
COPY goalscorers (date, home_team, away_team, team, scorer, minute, own_goal, penalty)
FROM 'C:\Users\joaof\Desktop\Projects_db\sql\Football\data\goalscorers.csv' -- data path
DELIMITER ','
CSV HEADER;
 
 
-- ------------------------------------------------------------
--  3. shootouts
--     date imported as TEXT — format is DD/MM/YYYY
--     will be converted in a later script
-- ------------------------------------------------------------
CREATE TABLE shootouts (
    date            TEXT        NOT NULL,
    home_team       VARCHAR(50) NOT NULL,
    away_team       VARCHAR(50) NOT NULL,
    winner          VARCHAR(50) NOT NULL,
    first_shooter   VARCHAR(50)
);
 
COPY shootouts (date, home_team, away_team, winner, first_shooter)
FROM 'C:\Users\joaof\Desktop\Projects_db\sql\Football\data\shootouts.csv' -- data path
DELIMITER ','
CSV HEADER
NULL '';
 
 
-- ------------------------------------------------------------
--  4. former_names
-- ------------------------------------------------------------
CREATE TABLE former_names (
    current     VARCHAR(50)  NOT NULL,
    former      VARCHAR(100) NOT NULL,
    start_date  DATE         NOT NULL,
    end_date    DATE         NOT NULL
);
 
COPY former_names (current, former, start_date, end_date)
FROM 'C:\Users\joaof\Desktop\Projects_db\sql\Football\data\former_names.csv' -- data path
DELIMITER ','
CSV HEADER;
 
 
-- ------------------------------------------------------------
--  Quick row count check — all 4 tables should have data
-- ------------------------------------------------------------
SELECT 'results'      AS table_name, COUNT(*) AS rows FROM results
UNION ALL
SELECT 'goalscorers'  AS table_name, COUNT(*) AS rows FROM goalscorers
UNION ALL
SELECT 'shootouts'    AS table_name, COUNT(*) AS rows FROM shootouts
UNION ALL
SELECT 'former_names' AS table_name, COUNT(*) AS rows FROM former_names;
