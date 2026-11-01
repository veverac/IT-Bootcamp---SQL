# Ilija Vasiljević
***
Završni projekat je osmišeljen tako da proveri naša znanja stečena tokom SQL dela kursa.

### Sastoji se iz tri dela:

- Deo A - Deset pitanja o podacima
- Deo B - Izveštaj o sezoni 2024/25 za upravu lige
- Deo C - pet pitanja sa prozorskim funkcijama

## Pretpostavke o zadacima

- U delu A, kod zadatka 7 uzeta je pretpostavka da se autogolovi ne računaju kao priznati golovi igraču.
- u delu B kod zadatka 3 odigrane utakmice sa nepoznatom posetom nisu uračunate u prosek.

## Deo D — Zvezdasta šema za analizu kartona

> - Napravljen je model sa jednom tabelom činjenica (fact_card) i četiri dimenzione tabele (dim_player, dim_team, dim_referee, dim_date).
> - Svaki red u fact_card predstavlja jedan dodeljeni karton, koji ima ključ event_id. Sa ostalim dimenzionim tabelama se povezuje pomoću ključeva player_id, team_id, referee_id i date_key.
> - kartoni imaju svoju tabelu činjenica kako bi se lakše analizirali. Bilo prema igraču, sudiji, timu ili datumu.