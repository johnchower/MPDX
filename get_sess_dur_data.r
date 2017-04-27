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

time_interval <- "month" # "week" or "month"
cohort_min_age <- 8
cohort_max_age <- 10
sess_dur_data_query_path <- paste(
  proj_root
  , "sess_dur_data.sql"
  , sep = "/"
)
sess_dur_data_result_path <- paste(proj_root, "sess_dur_data.csv", sep = "/")

# Get session duration data query results and write results to a directory

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

write.csv(
  sess_dur_data
  , file = sess_dur_data_result_path
  , row.names = F
)
