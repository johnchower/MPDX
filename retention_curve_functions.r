#####
# LOAD PACKAGES
#####

suppressMessages(library(dplyr))
suppressMessages(library(zoo))

diff_months <- function(
  date1
  , date2
){
    as.numeric(
      round(
        12 * (as.yearmon(date1) - as.yearmon(date2))
      )
    )
}

get_user_age <- function(
  sessDurData
  , runDate = Sys.Date()
  , time_interval = "week"
){
  if (time_interval == "week"){
    week_before_start <- seq.Date(from = runDate - 6, to = runDate, by = 1)
    start_week_beginning <-
      week_before_start[weekdays(week_before_start) == "Monday"]
    out <- sessDurData %>%
      group_by(user_id) %>%
      summarise(
        age = as.numeric(
          start_week_beginning - min(active_week_start_date)) / 7
        )
  } else if (time_interval == "month"){
    start_month_beginning <- as.Date(gsub("::$", "01", runDate))
    out <- sessDurData %>%
      group_by(user_id) %>%
      summarise(
        age = diff_months(
          start_month_beginning
          , min(active_month_start_date)
        )
      )
  }
  return(out)
}

create_rel_sess_dur_data <- function(
  sessDurData
  , runDate = Sys.Date()
  , time_interval = "week"
){
  if (time_interval == "week"){
    out <- sessDurData %>%
      group_by(user_id) %>%
      mutate(
        weeks_since_signup = (
          active_week_start_date - min(active_week_start_date)
        ) / 7
      ) %>%
      ungroup
  } else if (time_interval == "month"){
    out <- sessDurData %>%
      group_by(user_id) %>%
      mutate(
        months_since_signup = diff_months(
          active_month_start_date
          , min(active_month_start_date))
        )
  }
  return(out)
}

create_retention_curve_data <- function(
  userSet
  , sessDurData
  , runDate = Sys.Date()
  , userAges = user_ages
  , time_interval = "week"
){
  if (time_interval == "week"){
    filtered_data <- sessDurData %>%
      filter(user_id %in% userSet)
    num_users_by_age0 <- filtered_data %>%
      left_join(userAges, by = "user_id") %>%
      group_by(age) %>%
      filter(!is.na(age)) %>%
      summarise(number_of_users_this_age = length(unique(user_id))) %>%
      arrange(desc(age)) %>%
      rename(weeks_since_signup = age)
    max_age <- max(num_users_by_age0$weeks_since_signup)
    num_users_by_age <- num_users_by_age0 %>% {
      left_join(
        data.frame(weeks_since_signup = 0:max_age)
        , .
        , by = "weeks_since_signup"
      )
      } %>%
      mutate(
        number_of_users_this_age = ifelse(
          is.na(number_of_users_this_age)
          , 0
          , number_of_users_this_age
        )
      ) %>%
      arrange(desc(weeks_since_signup)) %>%
      mutate(number_of_users_past_this_age = cumsum(number_of_users_this_age))
    out <- filtered_data %>%
      create_rel_sess_dur_data(runDate, time_interval = "week") %>%
      left_join(num_users_by_age, by = "weeks_since_signup") %>%
      group_by(weeks_since_signup) %>%
      summarise(
        pct_active = length( unique(user_id)) /
          mean(number_of_users_past_this_age)
      )
  } else if (time_interval == "month"){
    filtered_data <- sessDurData %>%
      filter(user_id %in% userSet)
    num_users_by_age0 <- filtered_data %>%
      left_join(userAges, by = "user_id") %>%
      group_by(age) %>%
      filter(!is.na(age)) %>%
      summarise(number_of_users_this_age = length(unique(user_id))) %>%
      arrange(desc(age)) %>%
      rename(months_since_signup = age)
    max_age <- max(num_users_by_age0$months_since_signup)
    num_users_by_age <- num_users_by_age0 %>% {
      left_join(
        data.frame(months_since_signup = 0:max_age)
        , .
        , by = "months_since_signup"
      )
      } %>%
      mutate(
        number_of_users_this_age = ifelse(
          is.na(number_of_users_this_age)
          , 0
          , number_of_users_this_age
        )
      ) %>%
      arrange(desc(months_since_signup)) %>%
      mutate(number_of_users_past_this_age = cumsum(number_of_users_this_age))
    out <- filtered_data %>%
      create_rel_sess_dur_data(runDate, time_interval = "month") %>%
      left_join(num_users_by_age, by = "months_since_signup") %>%
      group_by(months_since_signup) %>%
      summarise(
        pct_active = length(unique(user_id)) /
          mean(number_of_users_past_this_age)
      )
  }
  return(out)
}
