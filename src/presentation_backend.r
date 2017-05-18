# This script produces all of the plots, models and summary stats for the
# presentation.rmd script.

proj_root <- rprojroot::find_root(rprojroot::has_dirname("mpdx"))

ProjectTemplate::load.project()

if (interactive()){
param_efficiency_analysis_threshold_pct <- 1
param_efficiency_analysis_threshold_week  <- 26
param_time_interval <- "month"
}
#############
# Preliminary calculations
#############

# Scatter plot data
funds_vs_pas_all <- wide_data.wide_data %>%
  presentation_functions.calculate_pa_scatter_data %>%
  mutate(post_gloo = nst_session %in% c("1318", "1526", "2798"))

funds_vs_pas <- wide_data.wide_data %>%
  filter(nst_session %in% c("1318", "1526", "2798")) %>%
  presentation_functions.calculate_pa_scatter_data

pct_ever_reached <- backend.user_reached_goal %>%
  left_join(backend.user_nst_session, by = "EMAIL_ADDR") %>%
  group_by(gloo_cohort) %>%
  summarise(pct_will_succeed = mean(eventually_reached_goal))

time_to_threshold_hist_data <- presentation_functions.get_time_to_threshold_hist_data(
  wide_data.wide_data
, param_efficiency_analysis_threshold_pct
, timeframe = param_efficiency_analysis_threshold_week
, filterByAge = T
)

# Platform action scatter plots

plot_max_pct_vs_pas <- funds_vs_pas %>%
  presentation_functions.make_pa_scatter_plot(
    pa_type = "pa_count"
  , plot_title = "Percentage of goal reached vs. Platform Actions Per Week"
  )
lm_max_pct_vs_pas <- funds_vs_pas %>%
  filter(max_total_pct_of_goal < Inf) %>% {
  lm(max_total_pct_of_goal ~ pa_count, data = .)
  }

plot_max_pct_vs_spaces <- funds_vs_pas %>%
  presentation_functions.make_pa_scatter_plot(
    pa_type = "space_count"
  , plot_title = "Percentage of goal reached vs. Platform Actions Per Week"
  )
lm_max_pct_vs_spaces <- funds_vs_pas %>%
  filter(max_total_pct_of_goal < Inf) %>% {
  lm(max_total_pct_of_goal ~ space_count, data = .)
  }

plot_max_pct_vs_content_progress <- funds_vs_pas %>%
  presentation_functions.make_pa_scatter_plot(
    pa_type = "content_progress_count"
  , plot_title = "Percentage of goal reached vs. Platform Actions Per Week"
  )
lm_max_pct_vs_content_progress <- funds_vs_pas %>%
  filter(max_total_pct_of_goal < Inf) %>% {
  lm(max_total_pct_of_goal ~ content_progress_count, data = .)
  }

# Histograms
funds_raised_vs_on_platform_all <- funds_vs_pas_all %>%
  presentation_functions.make_performance_histogram(
    performanceStatistic = "funds_raised"
  , binWidth = 50
  )

max_pct_vs_on_platform_all <- funds_vs_pas_all %>%
  filter(max_total_pct_of_goal < 1.5) %>%
  presentation_functions.make_performance_histogram(
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

plot_pct_goal_vs_hand_no_zeros <- wide_data.wide_data %>%
  filter(new_pct_of_goal <= 1.5) %>%
  filter(hand != 0) %>%
  presentation_functions.plot_metric_vs_assessment(
    assessment = "hand"
  , plot_title = "Portion of Goal Met vs hand Assessment Responses"
  )
lm_pct_goal_vs_hand_no_zeros <- wide_data.wide_data %>%
  filter(hand != 0) %>% {
  lm(new_pct_of_goal ~ hand, data = .)
  }

plot_pct_goal_vs_heart_no_zeros <- wide_data.wide_data %>%
  filter(new_pct_of_goal <= 1.5) %>%
  filter(heart != 0) %>%
  presentation_functions.plot_metric_vs_assessment(
    assessment = "heart"
  , plot_title = "Portion of Goal Met vs heart Assessment Responses"
  )
lm_pct_goal_vs_heart_no_zeros <- wide_data.wide_data %>%
  filter(heart != 0) %>% {
  lm(new_pct_of_goal ~ heart, data = .)
  }

plot_pct_goal_vs_head_no_zeros <- wide_data.wide_data %>%
  filter(new_pct_of_goal <= 1.5) %>%
  filter(head != 0) %>%
  presentation_functions.plot_metric_vs_assessment(
    assessment = "head"
  , plot_title = "Portion of Goal Met vs head Assessment Responses"
  )
lm_pct_goal_vs_head_no_zeros <- wide_data.wide_data %>%
  filter(head != 0) %>% {
  lm(new_pct_of_goal ~ head, data = .)
  }

# User success plots
user_success_plot_gloo <- backend.user_success_pct %>%
  filter(gloo_cohort) %>%
  presentation_functions.make_user_success_plot(
    max_days_since_class = 210
  )

user_success_plot_non_gloo <- backend.user_success_pct %>%
  filter(!gloo_cohort) %>%
  presentation_functions.make_user_success_plot(
    max_days_since_class = 210
  )

# Calculate assessment volatility through time
plot_h3_vol <- backend.h3_vol %>%
  ggplot(
    aes(
      x = weeks_since_class
    , y = volatility
    , color = nst_session
    )
  ) +
  facet_grid(assessment ~ .) +
  geom_point() +
  stat_smooth(method = "loess") +
  ggthemes::theme_tufte()

########
plot_time_to_threshold <- presentation_functions.plot_time_to_threshold_hist_data(
  time_to_threshold_hist_data
, binwidth = 1
) +
  scale_x_continuous(
    breaks = c(
      `0` = 0
    , `5` = 5
    , `10` = 10
    , `20` = 20
    , `25` = 25
    , `    > 25` = 26
    )
  )

pct_past_timeframe_data  <- time_to_threshold_hist_data %>%
  group_by(gloo_cohort) %>%
  summarise(
    pct_past_timeframe =
      mean(
        weeks_to_threshold >
          (param_efficiency_analysis_threshold_week - 1)
      )
  )
pct_gloo_users_past_timeframe <- pct_past_timeframe_data %>%
  filter(
    gloo_cohort
  ) %>% {
  .$pct_past_timeframe
  }
pct_other_users_past_timeframe <- pct_past_timeframe_data %>%
  filter(
    !gloo_cohort
  ) %>% {
  .$pct_past_timeframe
  }
avg_time_to_thresh_gloo <- time_to_threshold_hist_data %>%
  filter(
    gloo_cohort
  , weeks_to_threshold <=
      (param_efficiency_analysis_threshold_week - 1)
  ) %>%
  summarise(avg_time_to_thresh = mean(weeks_to_threshold)) %>% {
  .$avg_time_to_thresh
  }
avg_time_to_thresh_other <- time_to_threshold_hist_data %>%
  filter(
    !gloo_cohort
  , weeks_to_threshold <=
      (param_efficiency_analysis_threshold_week - 1)
  ) %>%
  summarise(avg_time_to_thresh = mean(weeks_to_threshold)) %>% {
  .$avg_time_to_thresh
  }
#######

# Retention Curve
cohort_min_age <- 8
cohort_max_age <- 10

user_ages <- retention_curve_functions.get_user_age(
  sdd.sess_dur_data
, time_interval = param_time_interval
)
cohort <- user_ages %>%
  filter(age >= cohort_min_age, age <= cohort_max_age)
retention_curve_data_list <- user_set_query_results.user_set_query_results %>%
  names %>% {
    .
  } %>%
  lapply(FUN = function(name){
    user_set_current <- user_set_query_results.user_set_query_results[[name]] %>%
      filter(user_id %in% cohort$user_id) %>% {
        .[["user_id"]]
      }
    retention_curve_data_current <- retention_curve_functions.create_retention_curve_data(
      user_set_current
    , sdd.sess_dur_data
    , time_interval = param_time_interval
    , userAges = user_ages
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
