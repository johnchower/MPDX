ProjectTemplate::load.project(
  override.config = list(
    munging = F
  , data_loading = F
  , cache_loading = F
  , load_libraries = T
  )
)

proj_root <- rprojroot::find_root(
  rprojroot::has_dirname("FamilyLifeSegmentation")
)

option_list <- list(
  optparse::make_option(
    "--auth_file_location"
  , type = "character"
  , default = ""
  , help = "Path to auth file containing database credentials"
  )
)
opt <- optparse::parse_args(optparse::OptionParser(option_list = option_list))

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
if (interactive()){
  auth_file_loc <- "~/.auth/authenticate"
} else {
  auth_file_loc <- opt$auth_file_location
}

auth <- readLines(auth_file_loc)

redshift_connection <- list(
  con = RPostgreSQL::dbConnect(
    drv = DBI::dbDriver("PostgreSQL")
  , dbname = auth[9]
  , host = auth[10]
  , port = auth[11]
  , user = auth[12]
  , password = auth[13]
  )
, drv = DBI::dbDriver("PostgreSQL")
)

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
