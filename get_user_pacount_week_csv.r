suppressMessages(library(dplyr))
proj_root <- rprojroot::find_root(rprojroot::has_dirname("mpdx"))
glootility::connect_to_redshift()

# Load Platform Actions Data Set
user_pacount_week_query <-
  paste(proj_root, "user_pacount_week.sql", sep = "/") %>%
  readLines %>%
  paste(collapse = " ")
user_pacount_week <- RPostgreSQL::dbGetQuery(
  conn = redshift_connection$con
  , statement = user_pacount_week_query
  )

write.csv(
  user_pacount_week
  , file = paste(proj_root, "user_pacount_week.csv", sep = "/")
  , row.names = F
)
