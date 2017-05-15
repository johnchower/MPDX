proj_root <- rprojroot::find_root(
  rprojroot::has_dirname("FamilyLifeSegmentation")
)

suppressMessages(library(dplyr))
suppressMessages(library(optparse))

if (!interactive()){
  optionList <-   list(
    optparse::make_option(
      opt_str =  "--auth_file_location"
    , type = "character"
    , default = ""
    , help = "Auth file containing database credentials"
    )
  )
  opt_parser <- optparse::OptionParser(option_list = optionList)
  opt <- optparse::parse_args(opt_parser)
  auth_file_loc <- opt$auth_file_location
} else {
  auth_file_loc <- "~/.auth"
}

csv_directory <- paste0(
  proj_root
  , "/"
  , "data"
  , "/"
)
query_directory <- paste0(
  proj_root
  , "/"
  , "queries"
  , "/"
)

glootility::connect_to_redshift(auth_file_location = auth_file_loc)

query_list <- query_directory %>% {
  paste0(., dir(.))
} %>%
lapply(
  FUN = function(x) gsub(
    pattern = ";"
  , replacement = ""
  , paste(readLines(x), collapse = " ")
  )
)

query_list_names <- dir(query_directory) %>% {
        gsub(pattern = ".sql", replacement = "", x = .)
    }

queries_to_run <- list()
for (i in 1:length(query_list)){
    new_entry <- list(query_name = query_list_names[i]
                      , query = query_list[[i]])
    queries_to_run[[length(queries_to_run) + 1]] <- new_entry
}

query_results <- glootility::run_query_list(
  queries_to_run
, connection = redshift_connection$con
)

print(csv_directory)
print(names(query_results))

query_results %>%
  names %>%
  lapply(function(name) {
    result_df <- query_results[[name]]
    out_file <- paste0(csv_directory, name, ".csv")
    write.csv(
      result_df
    , file = out_file
    , row.names = F
    )
  })
