WITH assessments_to_track AS (
SELECT id AS asst_assessment_id
FROM public.asst_assessment_dimensions
WHERE id IN 
  (604663544718296212,
  612857188793189860,
  604053626546030580,
  612859639281747469,
  604608947496682967,
  612853462690956680)
),
cohorts_to_track AS (
SELECT id AS cohort_id
FROM public.cohort_dimensions
WHERE id IN
  (1318,
  1526,
  2798)
),
results AS (
SELECT ud.email AS email
        , ucb.cohort_id AS cohort_id
        , dd.calendar_week_end_date AS assessment_week
        , dd.DATE AS assessment_date
        , aad.title AS assessment_title
        , aiod.position AS response
FROM public.assessment_facts af
left join public.user_dimensions ud
ON ud.surrogate_key = af.user_surrogate_key
left join public.user_to_cohort_bridges ucb
ON ucb.user_id = ud.id
left join public.date_dim dd
ON dd.id = af.date_id
left join public.asst_assessment_dimensions aad
ON aad.surrogate_key = af.asst_assessment_surrogate_key
left join public.asst_item_option_dimensions aiod
ON aiod.surrogate_key = af.asst_item_option_surrogate_key
WHERE af.asst_assessment_id IN 
        (SELECT asst_assessment_id FROM assessments_to_track)
AND ucb.cohort_id IN (SELECT cohort_id FROM cohorts_to_track)
AND (ud.account_type = 'End User' OR ud.account_type = 'Champion User')
), results2 AS (
SELECT email
        , cohort_id
        , assessment_date
        , assessment_week
        , assessment_title
        , avg(1.0*response) AS response
FROM results
GROUP BY email
        , cohort_id
        , assessment_date
        , assessment_week
        , assessment_title
)
SELECT * FROM results2
;
