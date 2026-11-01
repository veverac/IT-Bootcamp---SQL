-- Преглед сезоне: број утакмица и голова, просечан број голова по утакмици, удео победадомаћина, нерешених и победа гостију.


CREATE OR REPLACE VIEW bootcamp.northern_star.team_matches AS
    WITH sides AS (
        SELECT 
            match_id, season, matchday, kickoff_ts,
            home_team_id AS team_id, away_team_id AS opponent_id, 'home' AS
            venue,
            home_goals AS goals_for, away_goals AS goals_against
        FROM bootcamp.northern_star.matches WHERE status = 'played'
        UNION ALL
        SELECT 
            match_id, season, matchday, kickoff_ts,
            away_team_id, home_team_id, 'away',
            away_goals, home_goals
        FROM bootcamp.northern_star.matches WHERE status = 'played'
)
SELECT 
    *,
    CASE WHEN goals_for > goals_against THEN 'W'
         WHEN goals_for = goals_against THEN 'D' 
         ELSE 'L' 
    END AS result,
    CASE WHEN goals_for > goals_against THEN 3
         WHEN goals_for = goals_against THEN 1 
         ELSE 0 
    END AS points
FROM sides;

SELECT COUNT (match_id) AS broj_utakmica,
SUM (home_goals + away_goals) AS broj_golova,
ROUND (AVG (home_goals + away_goals),2) AS prosecan_broj_golova,
ROUND (SUM (CASE WHEN home_goals > away_goals THEN 1 ELSE 0 END) / COUNT (match_id) * 100.0,2)  AS udeo_pobeda_domacina,
ROUND (SUM (CASE WHEN home_goals = away_goals THEN 1 ELSE 0 END) / COUNT (match_id) * 100.0,2)  AS udeo_neresenih_utakmica,
ROUND (SUM (CASE WHEN home_goals < away_goals THEN 1 ELSE 0 END) / COUNT (match_id) * 100.0,2)  AS udeo_pobeda_gostiju
FROM matches
WHERE season = '2024/25';

-- 2. број утакмица и голова по месецима, и просечан број голова по утакмици усваком месецу. Који месец се издваја?

SELECT 
    COUNT (DISTINCT match_id) AS broj_utakmica, 
    DATE_FORMAT(kickoff_ts, 'yyyy-MM') AS mesec,
    SUM (goals_for) AS broj_golova, 
    ROUND (SUM (goals_for) / COUNT (DISTINCT match_id), 2) AS prosek 
FROM team_matches
WHERE season = '2024/25'
GROUP BY DATE_FORMAT(kickoff_ts, 'yyyy-MM')
ORDER BY prosek DESC;

-- Izdvaja se avgust 2024 godine, sa največim prosekom golova po odigranoj utakmici 3.54

-- 3. Публика: просечна посета и попуњеност по стадиону; утакмице без податка о посети иутакмица без публике.

SELECT s.stadium_name,
       ROUND (AVG (m.attendance),2) AS prosecna_poseta,
       ROUND (AVG (m.attendance) / s.capacity * 100.0 ,2) AS popunjenost,
       SUM (CASE WHEN m.attendance IS NULL THEN 1 ELSE 0 END) AS bez_podataka_o_poseti,
       SUM (CASE WHEN m.attendance = 0 THEN 1 ELSE 0 END) AS bez_publike
FROM matches m
JOIN stadiums s ON s.stadium_id = m.stadium_id
WHERE season = '2024/25' 
GROUP BY s.stadium_name, s.capacity
--ORDER BY prosecna_poseta DESC;
ORDER BY popunjenost DESC;

SELECT COUNT (*)
FROM matches
WHERE season = '2024/25' AND attendance = 0;

-- 4. Судије: за сваког судију број утакмица и картони по утакмици.


SELECT r.referee_name, COUNT (DISTINCT m.match_id), 
       SUM (CASE WHEN e.event_type IN ('red_card', 'yellow_card', 'second_yellow') THEN 1 ELSE 0 END) / COUNT (DISTINCT m.match_id) AS broj_kartona_po_utakmici
FROM matches m
JOIN match_events e ON e.match_id = m.match_id 
JOIN referees r ON r.referee_id = m.referee_id
WHERE m.season = '2024/25'
GROUP BY r.referee_name
ORDER BY broj_kartona_po_utakmici DESC;


-- 5. Играчи: пет најбољих стрелаца и пет најбољих асистената

SELECT p.first_name, p.last_name, COUNT(*) AS golovi
FROM match_events e
JOIN matches m ON e.match_id  = m.match_id
JOIN players p ON e.player_id = p.player_id
JOIN teams   t ON e.team_id   = t.team_id
WHERE m.season = '2024/25' AND e.event_type IN ('goal', 'penalty_goal')
GROUP BY p.player_id, p.first_name, p.last_name
ORDER BY golovi DESC
LIMIT 5;

SELECT p.first_name, p.last_name, COUNT(*) AS golovi
FROM match_events e
JOIN matches m ON e.match_id  = m.match_id
JOIN players p ON e.related_player_id = p.player_id
JOIN teams   t ON e.team_id   = t.team_id
WHERE m.season = '2024/25' AND e.event_type IN ('goal', 'penalty_goal')
GROUP BY p.player_id, p.first_name, p.last_name
ORDER BY golovi DESC
LIMIT 5;

-- Kvalitet podataka:

WITH iz_me AS(
    SELECT match_id, SUM(CASE WHEN event_type IN ('goal', 'penalty_goal', 'own_goal') THEN 1 END) AS broj_golova_me
    FROM match_events
    WHERE event_type IN ('goal', 'penalty_goal', 'own_goal')
    GROUP BY match_id
)
SELECT m.match_id, m.kickoff_ts,(m.home_goals + m.away_goals) AS broj_golova_m, e.broj_golova_me
FROM matches m
LEFT JOIN iz_me e ON m.match_id = e.match_id
WHERE  (m.home_goals + m.away_goals) <> COALESCE(e.broj_golova_me, 0) AND season ='2024/25';

SELECT m.match_id, th.team_name, ta.team_name, DATE(m.kickoff_ts), m.home_goals, m.away_goals
FROM matches m
JOIN teams th ON th.team_id = m.home_team_id
JOIN teams ta ON ta.team_id = m.away_team_id
WHERE match_id = 2227;

SELECT *
FROM match_events
WHERE match_id = 2227
ORDER BY event_type;

--Postoji neslaganje u broju golova iz match_events tabele i matches tabele,Na meču broj 2227, između Brackley Athletic i Pemberton United odigranog 2025-01-25 po podacima iz match_events postoji 4 pogodaka, a iz tabele matches postoji 3.

SELECT player_id, COUNT(*) AS broj_pojavljivanja
FROM match_events
WHERE player_id NOT IN (
    SELECT player_id
    FROM players
)
GROUP BY player_id;

-- postoji neslaganje u tabeli matches_events, igrač sa player_id brojem 99999 ne postoji u tabeli player_id.