-- dim_date

CREATE OR REPLACE TABLE dim_date AS
SELECT CAST(DATE_FORMAT(d, 'yyyyMMdd') AS INT) AS date_key,
       d                                       AS full_date,
       DATE_FORMAT(d, 'EEEE')                  AS weekday_name,
       DAYOFWEEK(d) IN (1, 7)                  AS is_weekend,
       CASE WHEN MONTH(d) >= 7 THEN CONCAT(YEAR(d), '/', SUBSTRING(CAST(YEAR(d) + 1 AS STRING), 3, 2))
            ELSE CONCAT(YEAR(d) - 1, '/', SUBSTRING(CAST(YEAR(d) AS STRING), 3, 2))
       END                                     AS season
FROM (SELECT EXPLODE(SEQUENCE(DATE'2023-07-01', DATE'2025-06-30', INTERVAL 1 DAY)) AS d);


-- dim_referee

CREATE OR REPLACE TABLE dim_referee AS
SELECT *
FROM referees;

--dim_teams

CREATE OR REPLACE TABLE dim_team AS
SELECT *
FROM teams;

-- dim_player

CREATE OR REPLACE TABLE dim_player AS
SELECT *
FROM players
UNION ALL
SELECT -1, 'Mile', 'Kitić', NULL, NULL, NULL, NULL, NULL,NULL;


-- dim_fact
CREATE OR REPLACE TABLE fact_card AS
SELECT e.event_id, e.match_id, CAST(DATE_FORMAT(m.kickoff_ts, 'yyyyMMdd') AS INT) AS date_key, e.team_id,
       CASE WHEN p.player_id IS NULL then -1
            ELSE e.player_id END AS player_id, m.referee_id, e.event_type as vrsta_kartona
FROM match_events e
JOIN matches m ON m.match_id = e.match_id
LEFT JOIN players p on p.player_id = e.player_id
WHERE e.event_type IN ('yellow_card', 'second_yellow', 'red_card');


SELECT COUNT(*) AS broj_redova
FROM fact_card; --2678

SELECT COUNT(*) AS broj_kartona
FROM match_events
WHERE event_type IN ('yellow_card', 'second_yellow', 'red_card'); --2678



SELECT COUNT(*) AS broj_kartona
FROM fact_card
WHERE player_id = -1;

-- Dva kartona ima player_id -1
