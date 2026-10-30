-- 1.Колики удео у укупном броју голова лиге у сезони 2024/25 има сваки клуб? Ко има највећи удео?





-- 2. Која су три стадиона са највећом просечном посетом у сезони 2024/25?

SELECT s.stadium_name, ROUND (AVG (attendance),2) AS prosecna_poseta,
DENSE_RANK () OVER (ORDER BY AVG (attendance) DESC) AS rng
FROM stadiums s
JOIN matches m on s.stadium_id = m.stadium_id
GROUP BY s.stadium_name
QUALIFY rng <=3
ORDER BY rng;

-- Harbourside Park	44415.63	1
-- Kingsbridge Stadium	40091.05	2
-- Northport Arena	35265.83	3

-- 3. 


-- 4.

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
