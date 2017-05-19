SELECT DISTINCT id AS user_id
FROM public.user_dimensions ud
WHERE ud.email IS NOT NULL
AND ud.account_type != 'Internal User'
;
