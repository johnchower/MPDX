suppressMessages(library(dplyr))
proj_root <- rprojroot::find_root(rprojroot::has_dirname("mpdx"))
glootility::connect_to_redshift()

# Load assessments data set
assessment_response_query <-
  paste(proj_root, "assessment_query.sql", sep = "/") %>%
  readLines %>%
  paste(collapse = " ")
assessment_response <- RPostgreSQL::dbGetQuery(
  conn = redshift_connection$con
, statement = assessment_response_query
)
write.csv(
  assessment_response
, file = paste(proj_root, "assessment_response.csv", sep = "/")
, row.names = F
)
