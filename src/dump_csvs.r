# Set time interval for retention curves 
source("./option_list.r")
opt <- optparse::parse_args(optparse::OptionParser(option_list = option_list))
param_time_interval <- opt$timeint
param_user_set_result_directory_name <- opt$usersetcsvdir
param_sess_dur_data_query_name <- opt$sessqueryname
param_efficiency_analysis_threshold_week <- opt$effthreshweek
param_efficiency_analysis_threshold_pct <- opt$effthreshpct

source("./presentation_backend.r")
csv_directory_name <- "csvs"

line_probability_drop_off <-
  ggplot_build(user_success_plot_gloo) %>% {
    .$data[[1]]
  } %>%
  select(weeks = x, probability = y) %>%
  filter(weeks <= 35)
write.csv(
  line_probability_drop_off
  , file = paste(
      proj_root
      , csv_directory_name
      , "line_probability_drop_off.csv"
      , sep = "/"
    )
  , row.names = F
)

line_probability_drop_off_pre_gloo <-
  ggplot_build(user_success_plot_non_gloo) %>% {
    .$data[[1]]
  } %>%
  select(weeks = x, probability = y) %>%
  filter(weeks <= 35)
write.csv(
  line_probability_drop_off
  , file = paste(
      proj_root
      , csv_directory_name
      , "line_probability_drop_off.csv"
      , sep = "/"
    )
  , row.names = F
)
write.csv(
  line_probability_drop_off_pre_gloo
  , file = paste(
      proj_root
      , csv_directory_name
      , "line_probability_drop_off_pre_gloo.csv"
      , sep = "/"
    )
  , row.names = F
)

bar_chart_funds_per_week <-
  funds_raised_vs_on_platform_all %>%
  ggplot_build %>% {
    .$data[[1]]
  } %>%
  select(cohort = PANEL, funds_raised_per_week = x, pct_users = y) %>%
  mutate(
    cohort = ifelse(
      cohort == 2
      , "Before Gloo"
      , "After Gloo"
  ))
write.csv(
  bar_chart_funds_per_week
  , file = paste(
      proj_root
      , csv_directory_name
      , "bar_chart_funds_per_week.csv"
      , sep = "/"
    )
  , row.names = F
)

time_to_threshold_hist_data <- get_time_to_threshold_hist_data(
  wide_data
  , param_efficiency_analysis_threshold_pct
  , timeframe = param_efficiency_analysis_threshold_week
)
plot_time_to_threshold <- plot_time_to_threshold_hist_data(
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

bar_chart_threshold_analysis <-
  plot_time_to_threshold %>%
  ggplot_build %>% {
    .$data[[1]]
  } %>%
  select(cohort = PANEL, weeks_to_threshold = x, pct_users = y) %>%
  mutate(
    cohort = ifelse(
      cohort == 2
      , "Before Gloo"
      , "After Gloo"
  ))
write.csv(
  bar_chart_threshold_analysis
  , file = paste(
      proj_root
      , csv_directory_name
      , "bar_chart_efficiency_analysis.csv"
      , sep = "/"
    )
  , row.names = F
)

bar_chart_pct_goal_attained <-
  max_pct_vs_on_platform_all %>%
  ggplot_build %>% {
    .$data[[1]]
  } %>%
  select(cohort = PANEL, max_pct_of_goal_attained = x, pct_users = y) %>%
  mutate(
    cohort = ifelse(
      cohort == 2
      , "Before Gloo"
      , "After Gloo"
  ))
write.csv(
  bar_chart_pct_goal_attained
  , file = paste(
      proj_root
      , csv_directory_name
      , "bar_chart_pct_goal_attained.csv"
      , sep = "/"
    )
  , row.names = F
)

scatter_volatility_list <-
  plot_h3_vol %>%
  ggplot_build %>% {
    .$data
  }
scatter_volatility <- scatter_volatility_list[[1]] %>%
  select(
    nst_session = colour
    , assessment = PANEL
    , weeks_since_class = x
    , sd_assessment = y
  ) %>%
  mutate(
    nst_session = ifelse(
      nst_session == "#F8766D"
      , "SU16"
      , "FA16"
    )
    , assessment = ifelse(
        assessment == "1"
        , "hand"
        , ifelse(
            assessment == "2"
            , "head"
            , "heart"
    ))
  )
write.csv(
  scatter_volatility
  , file = paste(
      proj_root
      , csv_directory_name
      , "scatter_volatility.csv"
      , sep = "/"
    )
  , row.names = F
)

trend_volatility <- scatter_volatility_list[[2]] %>%
  select(
    nst_session = colour
    , assessment = PANEL
    , weeks_since_class = x
    , trend_assessment = y
  ) %>%
  mutate(
    nst_session = ifelse(
      nst_session == "#F8766D"
      , "SU16"
      , "FA16"
    )
    , assessment = ifelse(
        assessment == "1"
        , "hand"
        , ifelse(
            assessment == "2"
            , "head"
            , "heart"
    ))
  )
write.csv(
  trend_volatility
  , file = paste(
      proj_root
      , csv_directory_name
      , "trend_volatility.csv"
      , sep = "/"
    )
  , row.names = F
)

scatter_max_pct_vs_pas <-
  plot_max_pct_vs_pas %>%
  ggplot_build %>% {
    .$data[[1]]
  } %>%
  select(
    pa_count = x
    , max_total_pct_of_goal = y
  )
write.csv(
  scatter_max_pct_vs_pas
  , file = paste(
      proj_root
      , csv_directory_name
      , "scatter_max_pct_vs_pas.csv"
      , sep = "/"
    )
  , row.names = F
)

scatter_max_pct_vs_spaces <-
  plot_max_pct_vs_spaces %>%
  ggplot_build %>% {
    .$data[[1]]
  } %>%
  select(
    pa_count = x
    , max_total_pct_of_goal = y
  )
write.csv(
  scatter_max_pct_vs_spaces
  , file = paste(
      proj_root
      , csv_directory_name
      , "scatter_max_pct_vs_spaces.csv"
      , sep = "/"
    )
  , row.names = F
)

scatter_max_pct_vs_content_progress <-
  plot_max_pct_vs_content_progress %>%
  ggplot_build %>% {
    .$data[[1]]
  } %>%
  select(
    pa_count = x
    , max_total_pct_of_goal = y
  )
write.csv(
  scatter_max_pct_vs_content_progress
  , file = paste(
      proj_root
      , csv_directory_name
      , "scatter_max_pct_vs_content_progress.csv"
      , sep = "/"
    )
  , row.names = F
)

scatter_pct_goal_vs_hand <-
  plot_pct_goal_vs_hand_no_zeros %>%
  ggplot_build %>% {
    .$data[[1]]
  } %>%
  select(
    hand_response = x
    , pct_progress_towards_goal = y
  )
write.csv(
  scatter_pct_goal_vs_hand
  , file = paste(
      proj_root
      , csv_directory_name
      , "scatter_pct_goal_vs_hand.csv"
      , sep = "/"
    )
  , row.names = F
)

scatter_pct_goal_vs_heart <-
  plot_pct_goal_vs_heart_no_zeros %>%
  ggplot_build %>% {
    .$data[[1]]
  } %>%
  select(
    heart_response = x
    , pct_progress_towards_goal = y
  )
write.csv(
  scatter_pct_goal_vs_heart
  , file = paste(
      proj_root
      , csv_directory_name
      , "scatter_pct_goal_vs_heart.csv"
      , sep = "/"
    )
  , row.names = F
)

scatter_pct_goal_vs_head <-
  plot_pct_goal_vs_head_no_zeros %>%
  ggplot_build %>% {
    .$data[[1]]
  } %>%
  select(
    head_response = x
    , pct_progress_towards_goal = y
  )
write.csv(
  scatter_pct_goal_vs_head
  , file = paste(
      proj_root
      , csv_directory_name
      , "scatter_pct_goal_vs_head.csv"
      , sep = "/"
    )
  , row.names = F
)

write.csv(
  retention_curve_data
  , file = paste(
      proj_root
      , csv_directory_name
      , "retention_curve_data.csv"
      , sep = "/"
    )
  , row.names = F
)
