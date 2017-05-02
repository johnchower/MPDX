proj_root <- rprojroot::find_root(rprojroot::has_dirname("mpdx"))
suppressMessages(library(optparse))
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
suppressMessages(library(zoo))
glootility::connect_to_redshift()
source("./retention_curve_functions.r")
source("./option_list.r")
source("./option_list.r")

opt <- parse_args(OptionParser(option_list = option_list))

time_interval <- opt$timeint # "week" or "month"
sess_dur_data_query_path <- paste0(
  proj_root
  , "/"
  , opt$sessqueryname
  , ".sql"
)
sess_dur_data_result_path <- paste0(
  proj_root
  , "/"
  , opt$sessqueryname
  , ".csv"
)

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
