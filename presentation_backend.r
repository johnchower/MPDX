proj_root <- rprojroot::find_root(rprojroot::has_dirname("mpdx"))
library(rpart)
library(plotly)
library(stats4)
library(tidyr)
library(plyr)
library(dplyr)
library(ggplot2)
library(scales)
library(broom)
library(extraDistr)
library(zoo)
glootility::connect_to_redshift()
source("./presentation_functions.r", local = T)
source("./retention_curve_functions.r", local = T)

wide_data <- read.csv(
  paste(proj_root, "mpd_stats_wide_3.csv", sep = "/")
  , stringsAsFactors = F
  ) %>%
  mutate(nst_session = as.character(nst_session))

funds_vs_pas_all <- wide_data %>%
  calculate_pa_scatter_data %>%
  mutate(post_gloo = nst_session %in% c("1318", "1526", "2798"))

funds_vs_pas <- wide_data %>%
  filter(nst_session %in% c("1318", "1526", "2798")) %>%
  calculate_pa_scatter_data

# Platform action scatter plots

plot_max_pct_vs_pas <- funds_vs_pas %>%
  make_pa_scatter_plot(
    pa_type = "pa_count"
    , plot_title = "Percentage of goal reached vs. Platform Actions Per Week"
  )
lm_max_pct_vs_pas <- funds_vs_pas %>%
  filter(max_total_pct_of_goal < Inf) %>% {
  lm(max_total_pct_of_goal ~ pa_count, data = .)
}

plot_max_pct_vs_spaces <- funds_vs_pas %>%
  make_pa_scatter_plot(
    pa_type = "space_count"
    , plot_title = "Percentage of goal reached vs. Platform Actions Per Week"
  )
lm_max_pct_vs_spaces <- funds_vs_pas %>%
  filter(max_total_pct_of_goal < Inf) %>% {
  lm(max_total_pct_of_goal ~ space_count, data = .)
}

plot_max_pct_vs_content_progress <- funds_vs_pas %>%
  make_pa_scatter_plot(
    pa_type = "content_progress_count"
    , plot_title = "Percentage of goal reached vs. Platform Actions Per Week"
  )
lm_max_pct_vs_content_progress <- funds_vs_pas %>%
  filter(max_total_pct_of_goal < Inf) %>% {
  lm(max_total_pct_of_goal ~ content_progress_count, data = .)
}

# Histograms
funds_raised_vs_on_platform_all <- funds_vs_pas_all %>%
  make_performance_histogram(
    performanceStatistic = "funds_raised"
    , binWidth = 50
  )

max_pct_vs_on_platform_all <- funds_vs_pas_all %>%
  filter(max_total_pct_of_goal < 1.5) %>%
  make_performance_histogram(
    performanceStatistic = "max_total_pct_of_goal"
    , binWidth = .1
  ) +
  scale_x_continuous(labels = percent)

# Summary stats
funds_raised_per_week_summary_stats <- funds_vs_pas_all %>%
  group_by(post_gloo) %>%
  summarise(
    avg_funds_raised_per_week = mean(funds_raised)
  )

# Explore correlation between assessment responses and percent of goal.

plot_pct_goal_vs_hand_no_zeros <- wide_data %>%
  filter(new_pct_of_goal <= 1.5) %>%
  filter(hand != 0) %>%
  plot_metric_vs_assessment(
    assessment = "hand"
    , plot_title = "Portion of Goal Met vs hand Assessment Responses"
  )
lm_pct_goal_vs_hand_no_zeros <- wide_data %>%
  filter(hand != 0) %>% {
    lm(new_pct_of_goal ~ hand, data = .)
  }

plot_pct_goal_vs_heart_no_zeros <- wide_data %>%
  filter(new_pct_of_goal <= 1.5) %>%
  filter(heart != 0) %>%
  plot_metric_vs_assessment(
    assessment = "heart"
    , plot_title = "Portion of Goal Met vs heart Assessment Responses"
  )
lm_pct_goal_vs_heart_no_zeros <- wide_data %>%
  filter(heart != 0) %>% {
    lm(new_pct_of_goal ~ heart, data = .)
  }

plot_pct_goal_vs_head_no_zeros <- wide_data %>%
  filter(new_pct_of_goal <= 1.5) %>%
  filter(head != 0) %>%
  plot_metric_vs_assessment(
    assessment = "head"
    , plot_title = "Portion of Goal Met vs head Assessment Responses"
  )
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

# User success plots
user_success_plot_gloo <- user_success_pct %>%
  filter(gloo_cohort) %>%
  make_user_success_plot(
    max_days_since_class = 210
  )

user_success_plot_non_gloo <- user_success_pct %>%
  filter(!gloo_cohort) %>%
  make_user_success_plot(
    max_days_since_class = 210
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

########
# Time to threshold analysis
# Currently, the functions for the time to threshold analysis are defined in
# presentation_functions.r, and all of the data manipulation happens in
# presentation.html
# The next commit will push the data manipulation back to this file, and
# abstract the 26-week timeframe into a parameter defined in the makefile.
# That code will go here, but for now this serves as a placeholder.
#######

# Retention Curve
cohort_min_age <- 8
cohort_max_age <- 10
user_set_result_directory <-
  paste(proj_root, param_user_set_result_directory_name, sep = "/")
user_set_result_directory_contents <- dir(user_set_result_directory)
user_set_result_directory_contents_noext <- gsub(
  pattern = ".csv"
  , replacement = ""
  , x = user_set_result_directory_contents
)

sess_dur_data <- read.csv(
  paste0(
    proj_root
    , "/"
    , param_sess_dur_data_query_name
    , ".csv"
))

user_set_query_results <- user_set_result_directory_contents %>%
  lapply(function(csv_name){
    full_path_to_csv <- paste(user_set_result_directory, csv_name, sep = "/")
    read.csv(full_path_to_csv)
  })
names(user_set_query_results) <- user_set_result_directory_contents_noext

if (param_time_interval == "week"){
  sess_dur_data <- sess_dur_data %>%
    mutate(active_week_start_date = as.Date(active_week_start_date))
} else if (param_time_interval == "month"){
  sess_dur_data <- sess_dur_data %>%
    mutate(active_month_start_date = as.Date(active_month_start_date))
}

user_ages <- get_user_age(sess_dur_data, time_interval = param_time_interval)
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
      , time_interval = param_time_interval
    )
    current_row_count <- nrow(retention_curve_data_current)
    cbind(retention_curve_data_current
       , data.frame(user_group = rep(name, times = current_row_count))
       )
  })

if (param_time_interval == "week"){
  retention_curve_data <- do.call(rbind, retention_curve_data_list) %>%
    mutate(weeks_since_signup = as.numeric(weeks_since_signup))
} else if (param_time_interval == "month"){
  retention_curve_data <- do.call(rbind, retention_curve_data_list) %>%
    mutate(months_since_signup = as.numeric(months_since_signup))
}

if (param_time_interval == "week"){
  plot_retention_curve <- retention_curve_data %>%
    filter(weeks_since_signup <= cohort_max_age) %>%
    ggplot(aes(x = weeks_since_signup, y = pct_active, color = user_group)) +
    geom_line() +
    ggthemes::theme_tufte()
} else if (param_time_interval == "month"){
  plot_retention_curve <- retention_curve_data %>%
    filter(months_since_signup <= cohort_max_age) %>%
    ggplot(aes(x = months_since_signup, y = pct_active, color = user_group)) +
    geom_line() +
    ggthemes::theme_tufte()
}
