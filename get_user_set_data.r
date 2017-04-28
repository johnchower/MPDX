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
source("./retention_curve_functions.r")
source("./option_list.r")

opt <- parse_args(OptionParser(option_list=option_list))

time_interval <- opt$timeint
user_set_query_directory <- paste(proj_root, "user_set_queries", sep = "/")
user_set_result_directory <- paste(proj_root, "user_sets", sep = "/")

# Get user set query results and write csvs to a directory
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
) %>%
  lapply(function(x) select(x, user_id)) 
user_set_query_result_names <- names(user_set_query_results)

user_set_query_result_names %>%
  lapply(function(name){
    current_dataset <- user_set_query_results[[name]]
    write.csv(
      current_dataset
      , file = paste0(user_set_result_directory, "/", name, ".csv")
      , row.names = F
    )
})
