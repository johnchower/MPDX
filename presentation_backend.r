proj_root <- rprojroot::find_root(rprojroot::has_dirname("mpdx"))
library(rpart)
library(plotly)
library(stats4)
library(gdata)
library(tidyr)
library(plyr)
library(dplyr)
library(ggplot2)
library(scales)
library(broom)
library(extraDistr)
library(zoo)
glootility::connect_to_redshift()
source("./retention_curve_functions.r")

wide_data <- read.csv(
  paste(proj_root, "mpd_stats_wide_3.csv", sep = "/")
  , stringsAsFactors = F
) %>%
  mutate(nst_session = as.character(nst_session))

funds_vs_pas_all <- wide_data %>%
  group_by(EMAIL_ADDR, nst_session) %>%
  summarise(num_weeks = length(unique(REPORT_DATE))
            , funds_raised = sum(NEW_MONTHLY_A) / num_weeks
            , pa_count = sum(pa_count) / num_weeks
            , space_count = sum(space_count) / num_weeks
            , content_progress_count = sum(content_progress_count) / num_weeks
            , contacts_made = sum(people_talked_to) / num_weeks
            , on_platform = sum(on_platform) > 0
            , funds_raised_per_contacts_made = funds_raised / contacts_made
            , max_total_pct_of_goal = max(total_pct_of_goal)
           ) %>%
  mutate(post_gloo = nst_session %in% c("1318", "1526", "2798"))

funds_vs_pas <- wide_data %>%
  filter(nst_session %in% c("1318", "1526", "2798")) %>%
  group_by(EMAIL_ADDR, nst_session) %>%
  summarise(num_weeks = length(unique(REPORT_DATE))
            , funds_raised = sum(NEW_MONTHLY_A) / num_weeks
            , pa_count = sum(pa_count) / num_weeks
            , space_count = sum(space_count) / num_weeks
            , content_progress_count = sum(content_progress_count) / num_weeks
            , contacts_made = sum(people_talked_to) / num_weeks
            , on_platform = sum(on_platform) > 0
            , funds_raised_per_contacts_made = funds_raised / contacts_made
            , max_total_pct_of_goal = max(total_pct_of_goal)
           )

# Platform action scatter plots

plot_max_pct_vs_pas <- funds_vs_pas %>%
  filter(max_total_pct_of_goal < 1.5) %>%
  rename(max_proportion_of_goal = max_total_pct_of_goal) %>%
  mutate(on_platform = ifelse(on_platform
                              , "On Platform"
                              , "Off Platform")) %>%
  ggplot(aes(x = pa_count
             , y = max_proportion_of_goal
             , color = on_platform)) +
  geom_point(alpha = .5) +
  geom_smooth(method = "lm", aes(color = "trend")) +
  ggtitle("Percentage of goal reached vs. Platform Actions Per Week") +
  ggthemes::theme_tufte()
lm_max_pct_vs_pas <- funds_vs_pas %>%
  filter(max_total_pct_of_goal < Inf) %>% {
  lm(max_total_pct_of_goal ~ pa_count, data = .)
}

plot_max_pct_vs_spaces <- funds_vs_pas %>%
  filter(max_total_pct_of_goal < 1.5) %>%
  rename(max_proportion_of_goal = max_total_pct_of_goal) %>%
  mutate(on_platform = ifelse(on_platform
                              , "On Platform"
                              , "Off Platform")) %>%
  ggplot(aes(x = space_count
             , y = max_proportion_of_goal
             , color = on_platform)) +
  geom_point(alpha = .5) +
  geom_smooth(method = "lm", aes(color = "trend")) +
  ggtitle("Percentage of goal reached vs. Platform Actions Per Week") +
  ggthemes::theme_tufte()
lm_max_pct_vs_spaces <- funds_vs_pas %>%
  filter(max_total_pct_of_goal < Inf) %>% {
  lm(max_total_pct_of_goal ~ space_count, data = .)
}

plot_max_pct_vs_content_progress <- funds_vs_pas %>%
  filter(max_total_pct_of_goal < 1.5) %>%
  rename(max_proportion_of_goal = max_total_pct_of_goal) %>%
  mutate(on_platform = ifelse(on_platform
                              , "On Platform"
                              , "Off Platform")) %>%
  ggplot(aes(x = content_progress_count
             , y = max_proportion_of_goal
             , color = on_platform)) +
  geom_point(alpha = .5) +
  geom_smooth(method = "lm", aes(color = "trend")) +
  ggtitle("Percentage of goal reached vs. Platform Actions Per Week") +
  ggthemes::theme_tufte()
lm_max_pct_vs_content_progress <- funds_vs_pas %>%
  filter(max_total_pct_of_goal < Inf) %>% {
  lm(max_total_pct_of_goal ~ content_progress_count, data = .)
}

# Histograms
contacts_made_vs_on_platform <- funds_vs_pas %>%
  mutate(on_platform = ifelse(on_platform
                              , "On Platform"
                              , "Off Platform")) %>%
  ggplot(aes(x = contacts_made)) +
  geom_histogram(aes(y = (..count..) /
                     tapply(..count.., ..PANEL.., sum)[..PANEL..]
                     )
                 , stat = "bin"
                 , binwidth = 10) +
  scale_y_continuous(labels = percent) +
  facet_grid(on_platform ~ .) +
  ggtitle("Contacts Made Per Week") +
  ylab("") +
  ggthemes::theme_tufte()

funds_raised_vs_on_platform <- funds_vs_pas %>%
  mutate(on_platform = ifelse(on_platform
                              , "On Platform"
                              , "Off Platform")) %>%
  ggplot(aes(x = funds_raised)) +
  geom_histogram(aes(y = (..count..) /
                     tapply(..count.., ..PANEL.., sum)[..PANEL..]
                     )
                 , stat = "bin"
                 , binwidth = 50) +
  scale_y_continuous(labels = percent) +
  # stat_density() +
  facet_grid(on_platform ~ .) +
  # ggtitle("Funds Raised Per Week") +
  ylab("") +
  ggthemes::theme_tufte()

funds_raised_vs_on_platform_all <- funds_vs_pas_all %>%
  mutate(
    post_gloo = ifelse(
      post_gloo
      , "After Gloo"
      , "Before Gloo"
  )) %>%
  ggplot(aes(x = funds_raised)) +
  geom_histogram(aes(y = (..count..) /
                     tapply(..count.., ..PANEL.., sum)[..PANEL..]
                     )
                 , stat = "bin"
                 , binwidth = 50) +
  scale_y_continuous(labels = percent) +
  # stat_density() +
  facet_grid(post_gloo ~ .) +
  # ggtitle("Funds Raised Per Week") +
  ylab("") +
  ggthemes::theme_tufte()

funds_raised_per_contact_vs_on_platform <- funds_vs_pas %>%
  mutate(on_platform = ifelse(on_platform
                              , "On Platform"
                              , "Off Platform")) %>%
  ggplot(aes(x = funds_raised_per_contacts_made)) +
  geom_histogram(aes(y = (..count..) /
                     tapply(..count.., ..PANEL.., sum)[..PANEL..]
                     )
                 , stat = "bin"
                 , binwidth = 2) +
  scale_y_continuous(labels = percent) +
  # stat_density() +
  facet_grid(on_platform ~ .) +
  # ggtitle("Funds Raised Per Contact Per Week") +
  ylab("") +
  ggthemes::theme_tufte()

funds_raised_per_contact_vs_on_platform_all <- funds_vs_pas_all %>%
  mutate(
    post_gloo = ifelse(
      post_gloo
      , "After Gloo"
      , "Before Gloo"
  )) %>%
  ggplot(aes(x = funds_raised_per_contacts_made)) +
  geom_histogram(aes(y = (..count..) /
                     tapply(..count.., ..PANEL.., sum)[..PANEL..]
                     )
                 , stat = "bin"
                 , binwidth = 2) +
  scale_y_continuous(labels = percent) +
  # stat_density() +
  facet_grid(post_gloo ~ .) +
  # ggtitle("Funds Raised Per Contact Per Week") +
  ylab("") +
  ggthemes::theme_tufte()

max_pct_vs_on_platform <- funds_vs_pas %>%
  filter(max_total_pct_of_goal < 1.5) %>%
  mutate(on_platform = ifelse(on_platform
                              , "On Platform"
                              , "Off Platform")) %>%
  ggplot(aes(x = max_total_pct_of_goal)) +
  geom_histogram(aes(y = (..count..) /
                     tapply(..count.., ..PANEL.., sum)[..PANEL..]
                     )
                 , stat = "bin"
                 , binwidth = .1) +
  scale_x_continuous(labels = percent) +
  scale_y_continuous(labels = percent) +
  # stat_density() +
  facet_grid(on_platform ~ .) +
  # ggtitle("Maximum percentage of goal reached") +
  ylab("") +
  ggthemes::theme_tufte()

max_pct_vs_on_platform_all <- funds_vs_pas_all %>%
  mutate(
    post_gloo = ifelse(
      post_gloo
      , "After Gloo"
      , "Before Gloo"
  )) %>%
  filter(max_total_pct_of_goal < 1.5) %>%
  ggplot(aes(x = max_total_pct_of_goal)) +
  geom_histogram(aes(y = (..count..) /
                     tapply(..count.., ..PANEL.., sum)[..PANEL..]
                     )
                 , stat = "bin"
                 , binwidth = .1) +
  scale_x_continuous(labels = percent) +
  scale_y_continuous(labels = percent) +
  # stat_density() +
  facet_grid(post_gloo ~ .) +
  # ggtitle("Maximum percentage of goal reached") +
  ylab("") +
  ggthemes::theme_tufte()

# Summary stats
get_max_pct_summary_stats <- function(fvpa, threshold){
fvpa %>%
  mutate(
    post_gloo = ifelse(
      post_gloo
      , "After Gloo"
      , "Before Gloo"
    )
    , reached_threshold = max_total_pct_of_goal >= threshold
  ) %>%
  mutate(
    ifelse(
      is.na(reached_threshold)
      , F
      , reached_threshold
    )
  ) %>%
  group_by(post_gloo) %>%
  summarise(pct_reached_threshold = mean(reached_threshold))
}

funds_raised_per_week_summary_stats <- funds_vs_pas_all %>%
  group_by(post_gloo) %>%
  summarise(
    avg_funds_raised_per_week = mean(funds_raised)
  )

# Explore differences across the three cohorts.
contacts_made_vs_on_platform_by_cohort <- funds_vs_pas %>%
  mutate(on_platform = ifelse(on_platform
                              , "On Platform"
                              , "Off Platform")) %>%
  ggplot(aes(x = contacts_made)) +
  geom_histogram(aes(y = (..count..) /
                     tapply(..count.., ..PANEL.., sum)[..PANEL..]
                     )
                 , stat = "bin"
                 , binwidth = 10
                 ) +
  scale_y_continuous(labels = percent) +
  facet_grid(nst_session ~ on_platform) +
  ggtitle("Contacts Made Per Week") +
  ylab("") +
  ggthemes::theme_tufte()

funds_raised_vs_on_platform_by_cohort <- funds_vs_pas %>%
  mutate(on_platform = ifelse(on_platform
                              , "On Platform"
                              , "Off Platform")) %>%
  ggplot(aes(x = funds_raised)) +
  geom_histogram(aes(y = (..count..) /
                     tapply(..count.., ..PANEL.., sum)[..PANEL..]
                     )
                 , stat = "bin"
                 , binwidth = 50
                 ) +
  scale_y_continuous(labels = percent) +
  # stat_density() +
  facet_grid(nst_session ~ on_platform) +
  ggtitle("Funds Raised Per Week") +
  ylab("") +
  ggthemes::theme_tufte()

funds_raised_per_contact_vs_on_platform_by_cohort <- funds_vs_pas %>%
  mutate(on_platform = ifelse(on_platform
                              , "On Platform"
                              , "Off Platform")) %>%
  ggplot(aes(x = funds_raised_per_contacts_made)) +
  geom_histogram(aes(y = (..count..) /
                     tapply(..count.., ..PANEL.., sum)[..PANEL..]
                     )
                 , stat = "bin"
                 , binwidth = 2
                 ) +
  scale_y_continuous(labels = percent) +
  # stat_density() +
  facet_grid(nst_session ~ on_platform) +
  ggtitle("Funds Raised Per Contact Per Week") +
  ylab("") +
  ggthemes::theme_tufte()

max_total_pct_of_goal_vs_on_platform_by_cohort <- funds_vs_pas %>%
  filter(max_total_pct_of_goal < 1.5) %>%
  mutate(on_platform = ifelse(on_platform
                              , "On Platform"
                              , "Off Platform")) %>%
  ggplot(aes(x = max_total_pct_of_goal)) +
  geom_histogram(aes(y = (..count..) /
                     tapply(..count.., ..PANEL.., sum)[..PANEL..]
                     )
                 , stat = "bin"
                 , binwidth = .1) +
  scale_x_continuous(labels = percent) +
  scale_y_continuous(labels = percent) +
  # stat_density() +
  facet_grid(nst_session ~ on_platform) +
  ggtitle("Maximum Percentage of Goal Reached") +
  ylab("") +
  ggthemes::theme_tufte()


# Explore correlation between time and fundraising success (do people do better
# after they've had some experience? Do they do better immediately after they
# attended their class?)

funds_vs_time <- wide_data %>%
  filter(nst_session %in% c("1318", "1526", "2798")
         , days_since_class >= 0
         ) %>%
  mutate(on_platform = ifelse(on_platform
                              , "On Platform"
                              , "Off Platform")
         )
funds_vs_time_plot <- funds_vs_time %>%
  ggplot(aes(x = days_since_class / 7
             , y = NEW_MONTHLY_A
             , color = nst_session
             )
         ) +
  geom_point(alpha = .5) +
  stat_smooth(method = "lm") +
  ggtitle("Funds Raised Per Week vs Time") +
  ggthemes::theme_tufte()

contacts_vs_time <- wide_data %>%
  filter(nst_session %in% c("1318", "1526", "2798")
         , days_since_class >= 0
         ) %>%
  mutate(on_platform = ifelse(on_platform
                              , "On Platform"
                              , "Off Platform")
         )
contacts_vs_time_plot <- contacts_vs_time %>%
  ggplot(aes(x = days_since_class / 7
             , y = people_talked_to
             , color = nst_session
             )
         ) +
  geom_point(alpha = .5) +
  stat_smooth(method = "lm") +
  ggtitle("Contacts Made Per Week vs Time") +
  ggthemes::theme_tufte()

######
# This stuff needs work
######
funds_per_contact_vs_time <- wide_data %>%
  filter(nst_session %in% c("1318", "1526", "2798")
         , days_since_class >= 0
         , people_talked_to > 0
         ) %>%
  mutate(on_platform = ifelse(on_platform
                              , "On Platform"
                              , "Off Platform")
         , funds_per_contact = NEW_MONTHLY_A / people_talked_to
         )
funds_per_contact_vs_time_plot <- funds_per_contact_vs_time %>%
  ggplot(aes(x = days_since_class / 7
             , y = funds_per_contact
             , color = nst_session
             )
         ) +
  geom_point(alpha = .5) +
  stat_smooth(method = "lm") +
  ggtitle("Funds Raised Per Contact vs Time") +
  ggthemes::theme_tufte()

new_pct_vs_time <- wide_data %>%
  filter(nst_session %in% c("1318", "1526", "2798")
         , days_since_class >= 0
         , people_talked_to > 0
         ) %>%
  mutate(on_platform = ifelse(on_platform
                              , "On Platform"
                              , "Off Platform")
         )
new_pct_vs_time_plot <- new_pct_vs_time %>%
  ggplot(aes(x = days_since_class / 7
             , y = new_pct_of_goal
             , color = nst_session
             )
         ) +
  geom_point(alpha = .5) +
  stat_smooth(method = "lm") +
  ggtitle("Percent of goal raised vs Time") +
  ggthemes::theme_tufte()

#######

lm_new_pct_vs_time <- funds_vs_time %>%
  filter(new_pct_of_goal < Inf) %>% {
  lm(new_pct_of_goal ~ days_since_class, data = .)
  }
lm_funds_vs_time <- funds_vs_time %>% {
  lm(NEW_MONTHLY_A ~ days_since_class, data = .)
  }
lm_funds_per_contact_vs_time <- funds_per_contact_vs_time %>% {
  lm(funds_per_contact ~ days_since_class, data = .)
  }
lm_contacts_vs_time <- contacts_vs_time %>% {
  lm(people_talked_to ~ days_since_class, data = .)
  }

# Explore correlation between assessment responses and percent of goal.

plot_pct_goal_vs_hand <- wide_data %>%
  filter(new_pct_of_goal <= 1.5) %>%
  ggplot(aes(y = new_pct_of_goal, x = hand)) +
  geom_point() +
  ggthemes::theme_tufte() +
  ggtitle("Portion of Goal Met vs hand Assessment Responses")
plot_pct_goal_vs_hand_no_zeros <- wide_data %>%
  filter(new_pct_of_goal <= 1.5) %>%
  filter(hand != 0) %>%
  ggplot(aes(y = new_pct_of_goal, x = hand)) +
  geom_point() +
  ggthemes::theme_tufte() +
  stat_smooth(method = "lm") +
  ggtitle("Portion of Goal Met vs hand Assessment Responses")
lm_pct_goal_vs_hand_no_zeros <- wide_data %>%
  filter(hand != 0) %>% {
    lm(new_pct_of_goal ~ hand, data = .)
  }

plot_pct_goal_vs_heart <- wide_data %>%
  filter(new_pct_of_goal <= 1.5) %>%
  ggplot(aes(y = new_pct_of_goal, x = heart)) +
  geom_point() +
  ggthemes::theme_tufte() +
  ggtitle("Portion of Goal Met vs heart Assessment Responses")
plot_pct_goal_vs_heart_no_zeros <- wide_data %>%
  filter(new_pct_of_goal <= 1.5) %>%
  filter(heart != 0) %>%
  ggplot(aes(y = new_pct_of_goal, x = heart)) +
  geom_point() +
  ggthemes::theme_tufte() +
  stat_smooth(method = "lm") +
  ggtitle("Portion of Goal Met vs heart Assessment Responses")
lm_pct_goal_vs_heart_no_zeros <- wide_data %>%
  filter(heart != 0) %>% {
    lm(new_pct_of_goal ~ heart, data = .)
  }

plot_pct_goal_vs_head <- wide_data %>%
  filter(new_pct_of_goal <= 1.5) %>%
  ggplot(aes(y = new_pct_of_goal, x = head)) +
  geom_point() +
  ggthemes::theme_tufte() +
  ggtitle("Portion of Goal Met vs head Assessment Responses")
plot_pct_goal_vs_head_no_zeros <- wide_data %>%
  filter(new_pct_of_goal <= 1.5) %>%
  filter(head != 0) %>%
  ggplot(aes(y = new_pct_of_goal, x = head)) +
  geom_point() +
  ggthemes::theme_tufte() +
  stat_smooth(method = "lm") +
  ggtitle("Portion of Goal Met vs head Assessment Responses")
lm_pct_goal_vs_head_no_zeros <- wide_data %>%
  filter(head != 0) %>% {
    lm(new_pct_of_goal ~ head, data = .)
  }

# Produce actionable stats 
max_report_date <- max(as.Date(wide_data$REPORT_DATE))
user_age <- wide_data %>%
  group_by(EMAIL_ADDR) %>%
  summarise(
    age_days = as.numeric(max_report_date - min(as.Date(REPORT_DATE)))
  )
user_reached_goal <- wide_data %>%
  group_by(EMAIL_ADDR) %>%
  summarise(eventually_reached_goal = sum(total_pct_of_goal >= 1) > 0)
user_day_reached_goal <- wide_data %>%
  group_by(EMAIL_ADDR) %>%
  summarise(
    day_reached_goal = ifelse(
      sum(total_pct_of_goal >= 1) > 0
      , min(days_since_class[total_pct_of_goal >= 1])
      , Inf
  ))
user_day_seq <- user_age %>%
  group_by(EMAIL_ADDR) %>%
  do({
    data.frame(
      days_since_class = seq(from = 0, to = .$age_days, by = 7)
    )
  }) %>%
  left_join(user_day_reached_goal, by = "EMAIL_ADDR") %>%
  mutate(reached_goal_yet = days_since_class >= day_reached_goal) %>%
  left_join(user_reached_goal, by = "EMAIL_ADDR") %>%
  ungroup

user_nst_session <- wide_data %>%
  distinct(EMAIL_ADDR, nst_session) %>%
  mutate(gloo_cohort = nst_session %in% c("1318", "1526", "2798"))

user_success_pct <- user_day_seq %>%
  left_join(user_nst_session, by = "EMAIL_ADDR") %>%
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

pct_ever_reached <- user_reached_goal %>%
  left_join(user_nst_session, by = "EMAIL_ADDR") %>%
  group_by(gloo_cohort) %>%
  summarise(pct_will_succeed = mean(eventually_reached_goal))

user_success_plot_gloo <- user_success_pct %>%
  filter(
    variable == "pct_will_succeed"
    , gloo_cohort
    , days_since_class <= 210
  ) %>%
  ungroup %>%
  mutate(
    weeks_since_class = days_since_class / 7
    , first_value = max(value)
    , value = value #/ first_value
  ) %>%
  ggplot(
    aes(
      x = weeks_since_class
      , y = value
      # , color = gloo_cohort
  )) +
  geom_line() +
  ggthemes::theme_tufte() +
  labs(
    x = "Weeks Without Meeting Support Goal"
    , y = "Probability of Meeting Support Goal"
  )

user_success_plot_non_gloo <- user_success_pct %>%
  filter(variable == "pct_will_succeed", !gloo_cohort) %>%
  ungroup %>%
  mutate(
    weeks_since_class = days_since_class / 7
    , first_value = max(value)
    , value = value #/ first_value
  ) %>%
  ggplot(
    aes(
      x = weeks_since_class
      , y = value
      # , color = gloo_cohort
  )) +
  geom_line() +
  ggthemes::theme_tufte() +
  labs(
    x = "Weeks Without Meeting Support Goal"
    , y = "Probability of Meeting Support Goal"
  )

# Calculate assessment volatility through time
h3_vol <- wide_data %>%
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

plot_h3_vol <- h3_vol %>%
  ggplot(
    aes(
      x = weeks_since_class
      , y = volatility
      , color = nst_session
  )) +
  facet_grid(assessment ~ .) +
  geom_point() +
  stat_smooth(method = "loess") +
  ggthemes::theme_tufte()

# Time to threshold analysis
get_time_to_threshold_hist_data <- function(
  wd
  , threshold
  , timeframe = 26 # weeks
  , userNST = user_nst_session
  , userAge = user_age
){
  wd %>%
    filter(days_since_class >= 0) %>%
    mutate(
      above_thresh = total_pct_of_goal >= threshold
    ) %>%
    group_by(EMAIL_ADDR) %>%
    summarise(
      ever_beat_thresh = sum(above_thresh) > 0
      , time_to_threshold = ifelse(
        !ever_beat_thresh
        , Inf
        , min(days_since_class[above_thresh])
      )
    ) %>%
    mutate(weeks_to_threshold = time_to_threshold / 7) %>%
    select(-time_to_threshold) %>%
    left_join(userNST, by = "EMAIL_ADDR") %>%
    left_join(userAge, by = "EMAIL_ADDR") %>%
    filter(age_days / 7 >= timeframe) %>%
    mutate(
      weeks_to_threshold = ifelse(
        weeks_to_threshold >= timeframe
        , timeframe
        , weeks_to_threshold
    ))
}
plot_time_to_threshold_hist_data <- function(ttthd, ...){
  ttthd %>%
    mutate(
      gloo_cohort = ifelse(
        gloo_cohort
        , "After Gloo"
        , "Before Gloo"
    )) %>%
    ggplot(aes(x = weeks_to_threshold)) +
    geom_histogram(
      aes(y = (..count..) /
            tapply(..count.., ..PANEL.., sum)[..PANEL..]
      )
      , stat = "bin"
      , ...
    ) +
    scale_y_continuous(labels = percent) +
    # stat_density() +
    facet_grid(gloo_cohort ~ .) +
    ggtitle("Time to reach threshold") +
    ylab("") +
    ggthemes::theme_tufte()
}

# Retention Curve
time_interval <- "month" # "week" or "month"
cohort_min_age <- 8
cohort_max_age <- 10
user_set_query_directory <- paste(proj_root, "user_set_queries", sep = "/")
sess_dur_data_query_path <- paste(
  proj_root
  , "./sess_dur_data_queries/sess_dur_data.sql"
  , sep = "/"
)

query_list <- paste(
  user_set_query_directory
  , dir(user_set_query_directory)
  , sep = "/"
  ) %>%
  lapply(
    FUN = function(x) gsub(
      pattern = ";"
      , replacement = ""
      , paste(readLines(x), collapse = " ")
    )
  )

query_list_names <- dir(user_set_query_directory) %>% {
        gsub(pattern = ".sql", replacement = "", x = .)
    }
           
queries_to_run <- list()
for (i in 1:length(query_list)){
    new_entry <- list(query_name = query_list_names[i]
                      , query = query_list[[i]])
    queries_to_run[[length(queries_to_run) + 1]] <- new_entry
}
user_set_query_results <- glootility::run_query_list(
  queries_to_run
  , connection = redshift_connection$con
)

sess_dur_data_query <- sess_dur_data_query_path %>%
  readLines %>%
  paste(collapse = " ") %>% {
    gsub(pattern = ";"
       , replacement = ""
       , .)
  } %>% {
    gsub(pattern = "xyz_time_interval_xyz"
       , replacement = time_interval
       , .)
  }

sess_dur_data <- RPostgreSQL::dbGetQuery(
  conn = redshift_connection$con
  , statement = sess_dur_data_query
)

if (time_interval == "week"){
  sess_dur_data <- sess_dur_data %>%
    mutate(active_week_start_date = as.Date(active_week_start_date))
} else if (time_interval == "month"){
  sess_dur_data <- sess_dur_data %>%
    mutate(active_month_start_date = as.Date(active_month_start_date))
}

user_ages <- get_user_age(sess_dur_data, time_interval = time_interval)
cohort <- user_ages %>%
  filter(age >= cohort_min_age, age <= cohort_max_age)
retention_curve_data_list <- user_set_query_results %>%
  names %>% {
    .
  } %>%
  lapply(FUN = function(name){
    user_set_current <- user_set_query_results[[name]] %>%
      filter(user_id %in% cohort$user_id) %>% {
        .[["user_id"]]
      }
    retention_curve_data_current <- create_retention_curve_data(
      user_set_current
      , sess_dur_data
      , time_interval = time_interval
    )
    current_row_count <- nrow(retention_curve_data_current)
    cbind(retention_curve_data_current
       , data.frame(user_group = rep(name, times = current_row_count))
       )
  })

if (time_interval == "week"){
  retention_curve_data <- do.call(rbind, retention_curve_data_list) %>%
    mutate(weeks_since_signup = as.numeric(weeks_since_signup))
} else if (time_interval == "month"){
  retention_curve_data <- do.call(rbind, retention_curve_data_list) %>%
    mutate(months_since_signup = as.numeric(months_since_signup))
}

if (time_interval == "week"){
  plot_retention_curve <- retention_curve_data %>%
    filter(weeks_since_signup <= cohort_max_age) %>%
    ggplot(aes(x = weeks_since_signup, y = pct_active, color = user_group)) +
    geom_line() +
    ggthemes::theme_tufte()
} else if (time_interval == "month"){
  plot_retention_curve <- retention_curve_data %>%
    filter(months_since_signup <= cohort_max_age) %>%
    ggplot(aes(x = months_since_signup, y = pct_active, color = user_group)) +
    geom_line() +
    ggthemes::theme_tufte()
}
