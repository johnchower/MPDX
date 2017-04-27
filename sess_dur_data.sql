WITH results_week AS (
SELECT ud.id AS user_id
        , dd.calendar_week_start_date AS active_week_start_date
FROM public.session_duration_fact sdf
inner join public.user_dimensions ud
ON sdf.user_surrogate_key = ud.surrogate_key
inner join public.date_dim dd
ON sdf.date_id = dd.id
GROUP BY ud.id, dd.calendar_week_start_date
),
results_month AS (
SELECT ud.id AS user_id
        , dd.calendar_year_month || '-01' AS active_month_start_date
FROM public.session_duration_fact sdf
inner join public.user_dimensions ud
ON sdf.user_surrogate_key = ud.surrogate_key
inner join public.date_dim dd
ON sdf.date_id = dd.id
GROUP BY ud.id, dd.calendar_year_month
)
SELECT *
FROM results_xyz_time_interval_xyz
;
