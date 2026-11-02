

-- 1. Колико утакмица је одиграно у фебруару 2025?

SELECT COUNT (match_id)
FROM matches
WHERE DATE(kickoff_ts) BETWEEN '2025-02-01' AND '2025-02-28' AND status = 'played';

-- U februaru 2025. godine odigrano je 40 utakmica.

-- 2.Који стадион има највећи капацитет, а који је највећи стадион неког клуба?

SELECT t.team_name, s.stadium_name, s.capacity
FROM stadiums s
LEFT JOIN teams t ON t.stadium_id = s.stadium_id
ORDER BY capacity DESC;

-- Nacionalni stadiijum ima najveći kapacitet (80000), a stadion tima Northport United, Harbourside Park (52000) je najveći stadion nekog kluba.

-- 3. Колико играча у лиги има српско држављанство (nationality = 'Serbia')?

SELECT COUNT (nationality)
FROM players
WHERE nationality = 'Serbia';

-- 42 igrača lige ima srpsko državljanstvo

-- 4.Колико утакмица је завршено резултатом 1:1?

SELECT COUNT (*)
FROM matches
WHERE home_goals = 1 AND away_goals = 1 AND status = 'played';

-- 94 utakmica je završeno rezultatom 1:1.

-- 5.Колика је просечна посета по сезони?

SELECT season, ROUND (AVG(attendance), 2) AS prosecna_poseta
FROM matches
WHERE status = 'played'
GROUP BY season;

-- Prosecna poseta u sezoni 2023/24 je 24276.2 a u sezoni 2024/25 je 24199.49.

-- 6. Колико голова је дато из пенала по сезони?

SELECT m.season, 
       SUM (CASE WHEN e.event_type = 'penalty_goal' THEN 1 ELSE 0 END) as broj_golova_iz_penala
FROM match_events e
JOIN matches m ON m.match_id = e.match_id
WHERE status = 'played' --suvišno u ovom slucaju, al neka ga ovde ;)
GROUP BY m.season;

-- U sezoni 2023/24	dato je 104, a u sezoni 2024/25	109 golova iz penala.

-- 7. Колико различитих играча је дало бар један гол у сезони 2024/25?

SELECT COUNT (DISTINCT e.player_id)
FROM match_events e
JOIN matches m ON m.match_id = e.match_id 
WHERE e.event_type IN ('goal', 'penalty_goal') AND m.season = '2024/25';

-- U sezoni 2024/25 ukupno 308 igrača je dalo barem jedan gol.

-- 8.Који судија је највише пута судио утакмице клуба Northport United?

SELECT r.referee_name, COUNT (*) AS broj_utakmica
FROM referees r
JOIN matches m ON r.referee_id = m.referee_id
JOIN teams th ON th.team_id = m.home_team_id
JOIN teams ta ON ta.team_id = m.away_team_id
WHERE th.team_name = 'Northport United' OR ta.team_name = 'Northport United' AND status = 'played'
GROUP BY r.referee_name
ORDER BY broj_utakmica DESC;

-- Najviše utakmica timu Northport United sudio je sudija Peter Lindgren, ukupno 9 utakmica.

-- 9. Који судија је у сезони 2024/25 имао највећи удео утакмица у којима је досуђен бар једанпенал, дат или промашен? 

WITH penal AS (
    SELECT COUNT (DISTINCT m.match_id) AS broj_utakmica_penal, m.referee_id
    FROM matches m
    JOIN match_events e ON m.match_id = e.match_id
    WHERE m.season = '2024/25' AND e.event_type IN ('penalty_goal', 'penalty_miss')
    GROUP BY m.referee_id
),
 sudija AS (
    SELECT COUNT (referee_id) AS broj_utakmica_po_sudiji, referee_id
    FROM matches 
    WHERE season = '2024/25' AND status = 'played'
    GROUP BY referee_id
)
SELECT  r.referee_name, ROUND (broj_utakmica_penal/ (broj_utakmica_po_sudiji)*100.0,2) AS udeo
FROM penal p
JOIN referees r on r.referee_id = p.referee_id
JOIN sudija s on s.referee_id = r.referee_id
ORDER BY udeo DESC;

-- Najveći udeo utakmica sa dosuđenim bar jednim penalom imao je Peter Lindgren	45 %.


-- 10.Који тренер је освојио највише бодова у утакмицама у којима је његов тим губио на полувремену? Рачунајте и домаће и гостујуће утакмице.

WITH sel_utakmice AS (
SELECT match_id, kickoff_ts, home_team_id AS team_id,
    CASE WHEN home_goals_ht < away_goals_ht AND home_goals > away_goals THEN 3  
         WHEN home_goals_ht < away_goals_ht AND home_goals = away_goals THEN 1 END AS broj_bodova
FROM matches
WHERE (home_goals_ht < away_goals_ht AND home_goals >= away_goals)
UNION
SELECT match_id, kickoff_ts, away_team_id,
       CASE WHEN home_goals_ht > away_goals_ht AND home_goals < away_goals THEN 3 
            WHEN home_goals_ht > away_goals_ht AND home_goals = away_goals THEN 1 END AS broj_bodova
FROM matches
WHERE (home_goals_ht > away_goals_ht AND home_goals <= away_goals)
)
SELECT ms.manager_name, SUM (broj_bodova) as ukupno_bodova
FROM sel_utakmice su
JOIN manager_spells ms ON ms.team_id = su.team_id AND start_date <= kickoff_ts AND COALESCE(end_date, '9999-12-31') >= kickoff_ts
GROUP BY ms.manager_name
ORDER BY ukupno_bodova DESC;

-- Zoran Tošić je osvojio najviše bodova u utakmicama u kojima je njegov tim gubio na poluvremenu, ukupno 18 bodova.