# This script does all of the data manipulation for the presentation_backend
# script.

# Gives each user an "age" in days, based on the earliest REPORT_DATE they
# have in wide_data.wide_data
# (EMAIL_ADDR, age_days)
backend.max_report_date <- max(as.Date(wide_data.wide_data$REPORT_DATE))
backend.user_age <- wide_data.wide_data %>%
  group_by(EMAIL_ADDR) %>%
  summarise(
    age_days = as.numeric(backend.max_report_date - min(as.Date(REPORT_DATE)))
  )

# Flags each user according to whether or not they ever reached their
# fundraising goal
# (EMAIL_ADDR, eventually_reached_goal)
backend.user_reached_goal <- wide_data.wide_data %>%
  group_by(EMAIL_ADDR) %>%
  summarise(eventually_reached_goal = sum(total_pct_of_goal >= 1) > 0)

# Associates each user to their nst_session, and flags them according to
# whether or not they used gloo.
# (EMAIL_ADDR, nst_session, gloo_cohort)
backend.user_nst_session <- wide_data.wide_data %>%
  distinct(EMAIL_ADDR, nst_session) %>%
  mutate(gloo_cohort = nst_session %in% c("1318", "1526", "2798"))

# Associates to each user the day that they reached their fundraising goal,
# relative to their class date. Set
# to infinity if they never reached their goal.
# (EMAIL_ADDR, day_reached_goal)
backend.user_day_reached_goal <- wide_data.wide_data %>%
  group_by(EMAIL_ADDR) %>%
  summarise(
    day_reached_goal = ifelse(
      sum(total_pct_of_goal >= 1) > 0
    , min(days_since_class[total_pct_of_goal >= 1])
    , Inf
    )
  )

# Intermediate calculation used for the next data set.
backend.user_day_seq <- backend.user_age %>%
  group_by(EMAIL_ADDR) %>%
  do({
    data.frame(
      days_since_class = seq(from = 0, to = .$age_days, by = 7)
    )
  }) %>%
  left_join(backend.user_day_reached_goal, by = "EMAIL_ADDR") %>%
  mutate(reached_goal_yet = days_since_class >= day_reached_goal) %>%
  left_join(backend.user_reached_goal, by = "EMAIL_ADDR") %>%
  ungroup

# For each week after the class date, 
# Calculates the percentage of users that haven't reached their goal yet, and
# the percentage of users who will eventually reach their goal of those who
# haven't reached their goal yet. Grouped by gloo_cohort.
# (days_since_class, gloo_cohort, pct_remaining, pct_will_succeed)
backend.user_success_pct <- backend.user_day_seq %>%
  left_join(backend.user_nst_session, by = "EMAIL_ADDR") %>%
  group_by(days_since_class, gloo_cohort) %>%
  summarise(
    pct_remaining = 1 - mean(reached_goal_yet)
  , pct_will_succeed = mean(eventually_reached_goal[!reached_goal_yet])
  ) %>%
  gather(
    key = "variable"
  , value = "value"
  , -days_since_class
  , -gloo_cohort
  )

# Calculate volatility in assessment responses through time
backend.h3_vol <- wide_data.wide_data %>%
  filter(
    nst_session %in% c("1318", "1526", "2798")
  , days_since_class >= 0
  ) %>%
  select(days_since_class, nst_session, hand, head, heart) %>%
  mutate(weeks_since_class = days_since_class / 7) %>%
  select(-days_since_class) %>%
  gather(
    key = "assessment"
  , value = "response"
  , -weeks_since_class
  , -nst_session
  ) %>%
  filter(!is.na(response), response != 0) %>%
  group_by(nst_session, weeks_since_class, assessment) %>%
  summarise(volatility = sd(response))


