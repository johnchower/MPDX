WITH uc AS (
SELECT DISTINCT user_id, cohort_id
FROM public.user_to_cohort_bridges
),
ue AS (
SELECT DISTINCT id, email
FROM public.user_dimensions
), user_facts AS (
SELECT ue.id
	, ue.email
	, uc.cohort_id
FROM ue
left join uc
ON uc.user_id=ue.id
), user_pa_week AS (
SELECT upaf.user_id
        , upaf.platform_action
	, dd.calendar_week_end_date
FROM public.user_platform_action_facts upaf
left join public.date_dim dd
ON dd.id=upaf.date_id
), user_pacount_week AS (
SELECT user_id
	, calendar_week_end_date AS pa_week
	, count(*) AS pa_count
        , sum((platform_action = 'Progressed Through Content')::INTEGER)
          AS content_progress_count
        , sum(
            (platform_action LIKE '%Space%' 
             AND platform_action NOT like '%Left%')::INTEGER
        ) AS space_count
FROM user_pa_week
GROUP BY user_id, calendar_week_end_date
), results AS (
SELECT DISTINCT
    uf.email
	, uf.cohort_id
	, upw.pa_week
	, upw.pa_count
	, upw.content_progress_count
	, upw.space_count
FROM user_facts uf
inner join user_pacount_week upw
ON uf.id=upw.user_id
WHERE uf.cohort_id IN (1318, 1526, 2798)
ORDER BY user_id, cohort_id, pa_week
)
SELECT *
FROM results
;
