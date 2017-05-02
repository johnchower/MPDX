# Random comment to rerun everything
proj_root <- rprojroot::find_root(rprojroot::has_dirname("mpdx"))
suppressMessages(library(rpart))
suppressMessages(library(plotly))
suppressMessages(library(stats4))
suppressMessages(library(tidyr))
suppressMessages(library(plyr))
suppressMessages(library(dplyr))
suppressMessages(library(ggplot2))
suppressMessages(library(scales))
suppressMessages(library(broom))
suppressMessages(library(extraDistr))
suppressMessages(library(data.table))
source(file = "./interpolate_goals.r")
glootility::connect_to_redshift()

proj_root <- rprojroot::find_root(rprojroot::has_dirname("mpdx"))

# Load data set
wide_data <- read.csv(paste(proj_root, "mpd_stats.csv", sep = "/"),
                           stringsAsFactors = F) %>%
  rename(REPORT_DATE = TO_CHAR.A.REPORT_DATE..YYYY.MM.DD..,
         LAST_PL_DATE = TO_CHAR.A.LAST_PL_DATE..YYYY.MM.DD..) %>%
  select(-PHONE) %>%
  mutate(SUPPORT_LETTERS = as.numeric(gsub(pattern = ",",
                                      replacement = "",
                                      x = SUPPORT_LETTERS)
                                     ),
         LAST_PL_DATE = gsub(pattern = "1016",
                             replacement = "2016",
                             x = LAST_PL_DATE)
        ) %>% {
    .[. == "N"] <- 0
    .[. == "Y"] <- 1
    return(.)
  } %>%
  mutate(people_talked_to =
           E_TALKED_TO_A +
           GROUP_MEET_ATTEND +
           INDIV_APPT_A +
           SUPPORT_LETTERS +
           TALKED_TO_A
         , money_per_people_talked_to =
            as.numeric(NEW_MONTHLY_A) / people_talked_to
         , on_platform = NST_SESSION %in% c("1318", "1526", "2798")
         , real_session = ifelse(NST_SESSION == "SU16"
                                 , "1526"
                                 , ifelse(NST_SESSION == "FA16"
                                          , "2798"
                                          , ifelse(NST_SESSION == "SP16"
                                                   , "1318"
                                                   , NST_SESSION
                                                  )
                                         )
                                )
          , class_week = ifelse(real_session == "1318"
                                , as.Date("2016-05-22")
                                , ifelse(real_session == "1526"
                                         , as.Date("2016-07-24")
                                         , ifelse(real_session == "2798"
                                                  , as.Date("2016-09-25")
                                                  , as.Date("2012-01-01")
                                                 )
                                        )
                               )
          , REPORT_DATE = as.Date(REPORT_DATE)
          , days_since_class = as.numeric(as.Date(REPORT_DATE) - class_week)
          , SUPPORT_GOAL = gsub(pattern = ","
                                , replacement = ""
                                , x = SUPPORT_GOAL)
        ) %>%
  mutate(
    days_since_class = ifelse(
      NST_SESSION %in% c("1318", "1526", "2798")
      , days_since_class
      , 7 * (as.numeric(MPD_WEEKS) - 1)
  )) %>%
  ungroup %>%
  select(-NST_SESSION) %>%
  rename(nst_session = real_session)

# Load Platform Actions Data Set
user_pacount_week <- read.csv(
  file = paste(proj_root, "user_pacount_week.csv", sep = "/")
  , stringsAsFactors = F
  ) %>%
  mutate(
    cohort_id = as.character(cohort_id)
    , pa_week = as.Date(pa_week)
  ) %>%
  rename(
    EMAIL_ADDR = email
    , nst_session = cohort_id
    , REPORT_DATE = pa_week
  )


# Load assessments data set
assessment_response <- read.csv(
  file = paste(proj_root, "assessment_response.csv", sep = "/")
  , stringsAsFactors = F
  ) %>%
  mutate(
    cohort_id = as.character(cohort_id)
    , assessment_week = as.Date(assessment_week)
#     , assessment_date = as.Date(assessment_date)
  ) %>%
  mutate(assessment_title = gsub(pattern = "MPD-H"
                                 , replacement = "h"
                                 , x = assessment_title)) %>%
  mutate(assessment_title = gsub(pattern = "[-()\\s]"
                                 , replacement = ""
                                 , x = assessment_title)) %>%
  mutate(assessment_title = gsub(pattern = "\\s"
                                 , replacement = ""
                                 , x = assessment_title)) %>%
  mutate(assessment_title = gsub(pattern = "Action"
                                 , replacement = ""
                                 , x = assessment_title)) %>%
  mutate(assessment_title = gsub(pattern = "Belief"
                                 , replacement = ""
                                 , x = assessment_title)) %>%
  mutate(assessment_title = gsub(pattern = "Feeling"
                                 , replacement = ""
                                 , x = assessment_title)) %>%
  rename(EMAIL_ADDR = email
         , nst_session = cohort_id
         , REPORT_DATE = assessment_week
         ) %>%
  unique %>%
  spread(key = assessment_title
         , value = "response")

# Join Platform actions in to first data set
wide_data_2 <- wide_data %>%
  left_join(user_pacount_week
            , by = c("EMAIL_ADDR", "nst_session", "REPORT_DATE")
  ) %>%
  left_join(assessment_response
            , by = c("EMAIL_ADDR", "nst_session", "REPORT_DATE")
  ) %>%
  select(NAME
         , EMAIL_ADDR
         , SUPPORT_GOAL
         , on_platform
         , nst_session
         , REPORT_DATE
         , MPD_WEEKS
         , LAST_PL_DATE
         , people_talked_to
         , days_since_class
         , NEW_MONTHLY_A
         , pa_count
         , content_progress_count
         , space_count
         , hand
         , head
         , heart
         , handStaff
         , headStaff
         , heartStaff
  ) %>%
  mutate(pa_count = ifelse(is.na(pa_count)
                           , 0
                           , pa_count)
         , space_count = ifelse(is.na(space_count)
                                , 0
                                , space_count)
         , content_progress_count = ifelse(is.na(content_progress_count)
                                           , 0
                                           , content_progress_count)
         , people_talked_to = as.numeric(people_talked_to)
         , NEW_MONTHLY_A = ifelse(is.na(as.numeric(NEW_MONTHLY_A))
                                  , 0
                                  , as.numeric(NEW_MONTHLY_A))
         , hand = ifelse(is.na(hand)
                         , 0
                         , hand)
         , head = ifelse(is.na(head)
                         , 0
                         , head)
         , heart = ifelse(is.na(heart)
                         , 0
                         , heart)
         , handStaff = ifelse(is.na(handStaff)
                         , 0
                         , handStaff)
         , headStaff = ifelse(is.na(headStaff)
                         , 0
                         , headStaff)
         , heartStaff = ifelse(is.na(heartStaff)
                         , 0
                         , heartStaff)
  )

# Fix up SUPPORT_GOAL data
wide_data_3 <-
  wide_data_2 %>%
  mutate(
    NEW_MONTHLY_A = ifelse(
      is.na(NEW_MONTHLY_A)
      , 0
      , as.numeric(NEW_MONTHLY_A)
    )
    , SUPPORT_GOAL = ifelse(
        is.na(SUPPORT_GOAL)
        , 0
        , as.numeric(SUPPORT_GOAL)
      )
  ) %>%
  group_by(
    EMAIL_ADDR
  ) %>%
  do({interpolate_goals(.)}) %>%
  ungroup %>%
  left_join(
    select(wide_data_2, -SUPPORT_GOAL)
    , by = c("EMAIL_ADDR", "REPORT_DATE")
  ) %>%
  group_by(EMAIL_ADDR) %>%
  arrange(days_since_class) %>%
  mutate(
    total_raised = cumsum(NEW_MONTHLY_A)
    , new_pct_of_goal = NEW_MONTHLY_A / SUPPORT_GOAL
    , total_pct_of_goal = total_raised / SUPPORT_GOAL
  ) %>%
  mutate(
    total_pct_of_goal = ifelse(
      SUPPORT_GOAL == 0
      , 0
      , total_pct_of_goal
    )
    , new_pct_of_goal = ifelse(
      SUPPORT_GOAL == 0
      , 0
      , total_pct_of_goal
    )
  ) %>%
  ungroup

# Fill in missing rows.
max_days_since_class_by_nst_session <- wide_data_3 %>%
  group_by(nst_session) %>%
  summarise(max_days_since_class = max(days_since_class))

seq_days_by_nst_session <- max_days_since_class_by_nst_session %>%
  group_by(nst_session) %>%
  do({
    data.frame(
      days_since_class = seq(
        from = 0
        , to = .$max_days_since_class
        , by = 7
      )
      , stringsAsFactors = F
    )
  }) %>%
  left_join(
    select(wide_data_3, EMAIL_ADDR, nst_session)
    , by = "nst_session"
  )

wide_data_4  <- seq_days_by_nst_session %>%
  left_join(
    wide_data_3
    , by = c("EMAIL_ADDR", "nst_session")
  )

# Write to csv
write.csv(wide_data_3,
        paste(proj_root, "mpd_stats_wide_3.csv", sep = "/"),
        row.names = F)
