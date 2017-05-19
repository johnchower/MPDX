WITH
champions_of_interest AS (
SELECT DISTINCT cd.id AS champion_id
FROM public.champion_dimensions cd
WHERE cd.id IN (13, 6, 9, 137, 143)
),
user_first_second_wide AS (
SELECT uccb.user_id
        , sum(
            (uccb.sequence_number=1)::INTEGER*uccb.champion_id
        ) AS first_champ
        , sum(
            (uccb.sequence_number=2)::INTEGER*uccb.champion_id
        ) AS second_champ
FROM public.user_connected_to_champion_bridges uccb
GROUP BY uccb.user_id
),
user_true_first_champ AS (
SELECT ufsw.user_id
        , case
        when ufsw.second_champ = 0
            THEN ufsw.first_champ
        when first_champ = 1
            THEN ufsw.second_champ
        ELSE ufsw.first_champ
        end AS true_first_champ
FROM user_first_second_wide ufsw
),
users_belonging_to_coi AS (
SELECT DISTINCT user_id
FROM user_true_first_champ
WHERE true_first_champ NOT IN (SELECT champion_id FROM champions_of_interest)
),
results AS (
SELECT ubtc.*
FROM users_belonging_to_coi ubtc
inner join public.user_dimensions ud
ON ud.id = ubtc.user_id
WHERE ud.account_type != 'Internal User'
)
SELECT *
FROM results
;
