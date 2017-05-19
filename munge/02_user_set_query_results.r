# This script organizes all of the user set data frames into a single list
# Datasets produced:
# user_set_query_results.user_set_query_results - 
#   A named list containing all of the user_set data frames

user_set_data_frames <- grep(
  pattern = "user\\.set\\."
, x = ls()
, value = T 
) 

names(user_set_data_frames) <- user_set_data_frames

user_set_query_results.user_set_query_results <- user_set_data_frames %>%
  as.list %>%
  lapply(get)

names(user_set_query_results.user_set_query_results) <- 
  names(user_set_query_results.user_set_query_results) %>% {
  gsub(
    pattern = "\\."
  , replacement = "_"
  , x = .
  ) %>%
  gsub(
    pattern = "user_set_"
  , replacement = ""
  , x = .
  )
}

names(user_set_data_frames) <- NULL
rm(list = user_set_data_frames)
