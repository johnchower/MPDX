# Given a data frame like long_data, interpolate values for fundraising goals
# based on the following rules:
# 1. If they've only ever had one goal, then that's their goal every week.
# 2. If they've had more than one goal, then their goal every week is the most
# recent goal that they've stated in the past, or if that doesn't exist, 
# their first stated goal.
# 3. If they've never stated a goal, then their goal every week is 0. Users
# with a negative goal will be excluded from the analysis.
# @param input_df A data.frame in the same form as long_data, filtered so that
# the only variable is SUPPORT_GOAL.
# @return A data.frame of the form (REPORT_DATE, value), where value represents
# the fundraising goal.
interpolate_goals <- function(input_df){
    distinct_goals <- unique(input_df$SUPPORT_GOAL[input_df$SUPPORT_GOAL != 0])
    number_of_reports <- length(input_df$REPORT_DATE)
    if (length(distinct_goals) == 1){
      goal <- rep(distinct_goals
                  , times = number_of_reports)
      out <- data.frame(
        REPORT_DATE = input_df$REPORT_DATE
        , SUPPORT_GOAL = goal
        , stringsAsFactors = F
      )
    } else if (length(distinct_goals) == 0){
      goal <- rep(0
                  , times = number_of_reports)
      out <- data.frame(
        REPORT_DATE = input_df$REPORT_DATE
        , SUPPORT_GOAL = goal
        , stringsAsFactors = F
      )
    } else {
      no_zeros <- input_df %>%
        filter(SUPPORT_GOAL != 0) %>%
        select(REPORT_DATE, no_zeros_SUPPORT_GOAL = SUPPORT_GOAL)
      all_rows <- input_df %>%
        select(REPORT_DATE, all_rows_SUPPORT_GOAL = SUPPORT_GOAL)
      no_zeros <- data.table::as.data.table(no_zeros)
      data.table::setkey(no_zeros, "REPORT_DATE")
      all_rows <- data.table::as.data.table(all_rows)
      data.table::setkey(all_rows, "REPORT_DATE")
      out <- no_zeros[
        all_rows
        , .(
            REPORT_DATE
            , all_rows_SUPPORT_GOAL
            , no_zeros_SUPPORT_GOAL
          )
        , roll = T
      ]
      out <- out %>%
        mutate(
          no_zeros_SUPPORT_GOAL = ifelse(
            is.na(no_zeros_SUPPORT_GOAL)
            , mean(no_zeros_SUPPORT_GOAL[!is.na(no_zeros_SUPPORT_GOAL)])
            , no_zeros_SUPPORT_GOAL
          )
        ) %>%
        select(
          REPORT_DATE
          , SUPPORT_GOAL = no_zeros_SUPPORT_GOAL
        )
    }
    out
}
