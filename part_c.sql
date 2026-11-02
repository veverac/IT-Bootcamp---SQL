-- 1.Колики удео у укупном броју голова лиге у сезони 2024/25 има сваки клуб? Ко има највећи удео?

WITH golovi_po_timu AS(
        SELECT team_id, SUM (goals_for) AS broj_golova 
        FROM team_matches
        WHERE season = '2024/25'
        GROUP BY team_id
    )
SELECT t.team_name, ROUND (g.broj_golova/ SUM (g.broj_golova) OVER () * 100.0, 2) as pct
FROM golovi_po_timu g
JOIN teams t ON t.team_id = g.team_id
ORDER BY pct DESC;

-- Najveći udeo ima Kingsbridge City 7.6 %.

-- 2. Која су три стадиона са највећом просечном посетом у сезони 2024/25?

SELECT s.stadium_name, ROUND (AVG (attendance),2) AS prosecna_poseta,
DENSE_RANK () OVER (ORDER BY AVG (attendance) DESC) AS rng
FROM stadiums s
JOIN matches m on s.stadium_id = m.stadium_id
WHERE m.season = '2024/25'
GROUP BY s.stadium_name
QUALIFY rng <=3
ORDER BY rng;

-- Harbourside Park	44074.05	1
-- Kingsbridge Stadium	37968.42	2
-- Northport Arena	36250.17	3

-- 3. За сваки клуб, ко је дао последњи гол клуба у сезони 2024/25 и када? Који клуб је последњи гол дао најраније?

WITH golovi AS (
SELECT e.match_id, m.kickoff_ts, m.season, e.player_id, e.team_id, e.minute, e.added_time
FROM match_events e
JOIN matches m ON e.match_id = m.match_id
Where event_type IN ('goal', 'penalty_goal') AND m.season = '2024/25'
)
SELECT p.first_name, p.last_name, t.team_name, DATE (g.kickoff_ts), g.minute, COALESCE(g.added_time, 0)
FROM golovi g
JOIN teams t ON t.team_id = g.team_id
JOIN players p ON p.player_id = g.player_id
QUALIFY  ROW_NUMBER () OVER (PARTITION BY g.team_id ORDER BY g.kickoff_ts DESC, g.minute DESC, COALESCE(g.added_time, 0) DESC) = 1
ORDER BY g.kickoff_ts, g.minute, g.added_time; 

-- Marko	Stanković	Elmsworth Wanderers	2025-05-03	27	0

-- 4. За домаће утакмице клуба Northport United у сезони 2024/25 прикажите посету и промену у односу на претходну домаћу утакмицу. Где је највећи пад?

WITH club AS(
    SELECT team_id FROM teams WHERE team_name ='Northport United'
),
razlika_posete AS (
SELECT match_id, home_team_id, season, attendance, kickoff_ts,
        LAG (attendance) OVER (PARTITION BY home_team_id, season ORDER BY kickoff_ts) AS prethodna_poseta,
        attendance - prethodna_poseta AS razlika_posete
FROM matches
)
SELECT r.match_id, r.home_team_id, r.attendance, r.razlika_posete, r.season,
        row_number() OVER (ORDER BY razlika_posete) AS rn
FROM razlika_posete r
JOIN club c ON c.team_id = r.home_team_id
WHERE razlika_posete IS NOT NULL and r.season = '2024/25'
QUALIFY rn =1;

SELECT * 
FROM matches
WHERE  match_id = 2110;

-- najveći pad je na utakmici protiv Castlebrook United gde su izgubili sa 2:4, 10 Novembra 2024. godine.

-- 5.Пратите бодове клуба Northport City утакмицу по утакмицу у сезони 2024/25 . У којојутакмици по реду и ког датума је прешао 50 бодова?

WITH club AS (
SELECT team_id
FROM teams
WHERE team_name = 'Northport City'
),
bod AS (
SELect c.team_id, m.kickoff_ts,
    COUNT (*) OVER w AS broj_utakmica,
    sum(m.points) over w as broj_bodova
from team_matches m
JOIN club c ON c.team_id = m.team_id
where season = '2024/25'
window w as( PARTITION BY m.team_id
    ORDER BY kickoff_ts
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) 
QUALIFY broj_bodova >= 50
)
SELECT team_id, DATE(kickoff_ts), broj_utakmica,
    ROW_NUMBER () OVER (PARTITION BY team_id ORDER BY kickoff_ts) as rnk
FROM bod
QUALIFY rnk =1
ORDER BY kickoff_ts;

-- Dana 12 januara 2025 godine klub Northport City je stigao do 50 bodova, u 21 utakmici u sezoni.
