presentation_functions.calculate_pa_scatter_data <- function(wideData){
  wideData %>%
    group_by(EMAIL_ADDR, nst_session) %>%
    summarise(
      num_weeks = length(unique(REPORT_DATE))
    , funds_raised = sum(NEW_MONTHLY_A) / num_weeks
    , pa_count = sum(pa_count) / num_weeks
    , space_count = sum(space_count) / num_weeks
    , content_progress_count = sum(content_progress_count) / num_weeks
    , contacts_made = sum(people_talked_to) / num_weeks
    , on_platform = sum(on_platform) > 0
    , funds_raised_per_contacts_made = funds_raised / contacts_made
    , max_total_pct_of_goal = max(total_pct_of_goal)
    )
}

presentation_functions.make_pa_scatter_plot <- function(
  data_funds_vs_pas
, pa_type
, plot_title = ""
){
  data_funds_vs_pas %>%
    filter(max_total_pct_of_goal < 1.5) %>%
    rename(max_proportion_of_goal = max_total_pct_of_goal) %>%
    mutate(
      on_platform = ifelse(
        on_platform
      , "On Platform"
      , "Off Platform"
      )
    ) %>%
    ggplot(
      aes_string(
        x = pa_type
      , y = "max_proportion_of_goal"
      , color = "on_platform"
      )
    ) +
    geom_point(alpha = .5) +
    geom_smooth(method = "lm", aes(color = "trend")) +
    ggtitle(plot_title) +
    ggthemes::theme_tufte()
}

presentation_functions.make_performance_histogram <- function(
  data_funds_vs_pas_all
, performanceStatistic
, binWidth
){
  data_funds_vs_pas_all %>%
    mutate(
      post_gloo = ifelse(
        post_gloo
      , "After Gloo"
      , "Before Gloo"
      )
    ) %>%
    ggplot(aes_string(x = performanceStatistic)) +
    geom_histogram(
      aes(
        y =
          (..count..) /
          tapply(..count.., ..PANEL.., sum)[..PANEL..]
      )
      , stat = "bin"
      , binwidth = binWidth
    ) +
    scale_y_continuous(labels = percent) +
    facet_grid(post_gloo ~ .) +
    ylab("") +
    ggthemes::theme_tufte()
}

presentation_functions.get_max_pct_summary_stats <- function(fvpa, threshold){
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

presentation_functions.get_time_to_threshold_hist_data <- function(
  wd
, threshold
, timeframe = 26 # weeks
, userNST = backend.user_nst_session
, userAge = backend.user_age
, filterByAge = T
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
    left_join(userAge, by = "EMAIL_ADDR") %>% {
      if (filterByAge){
        out <- filter(., age_days / 7 >= timeframe)
      } else {out <- .}
      return(out)
    } %>%
    mutate(
      weeks_to_threshold = ifelse(
        weeks_to_threshold >= timeframe
      , timeframe
      , weeks_to_threshold
      )
    )
}

presentation_functions.plot_time_to_threshold_hist_data <- function(
  ttthd
, ...
){
  ttthd %>%
    mutate(
      gloo_cohort = ifelse(
        gloo_cohort
      , "After Gloo"
      , "Before Gloo"
      )
    ) %>%
    ggplot(aes(x = weeks_to_threshold)) +
    geom_histogram(
      aes(
        y =
          (..count..) /
          tapply(..count.., ..PANEL.., sum)[..PANEL..]
      )
    , stat = "bin"
    , ...
    ) +
    scale_y_continuous(labels = percent) +
    facet_grid(gloo_cohort ~ .) +
    ggtitle("Time to reach threshold") +
    ylab("") +
    ggthemes::theme_tufte()
}

presentation_functions.plot_metric_vs_assessment <- function(
  wideData
, performanceStatistic = "new_pct_of_goal"
, assessment = "hand"
, plot_title = ""
, smoothMethod = "lm"
){
  wideData %>%
    ggplot(aes_string(y = performanceStatistic, x = assessment)) +
    geom_point() +
    ggthemes::theme_tufte() +
    stat_smooth(method = smoothMethod) +
    ggtitle(plot_title)
}

presentation_functions.make_user_success_plot <- function(
  user_success_pct_data
, max_days_since_class = Inf
){
  user_success_pct_data %>%
    filter(
      variable == "pct_will_succeed"
    , days_since_class <= max_days_since_class
    ) %>%
    ungroup %>%
    mutate(
      weeks_since_class = days_since_class / 7
    , first_value = max(value)
    , value = value
    ) %>%
    ggplot(
      aes(
        x = weeks_since_class
      , y = value
      )
    ) +
    geom_line() +
    ggthemes::theme_tufte() +
    labs(
      x = "Weeks Without Meeting Support Goal"
    , y = "Probability of Meeting Support Goal"
    )
}
