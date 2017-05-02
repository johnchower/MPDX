suppressMessages(library(optparse))
option_list <- list(
  make_option(
    "--usersetcsvdir"
    , type = "character"
    , default = "user_sets"
    , help = "The directory to place user set csvs [default %default]"
  ),
  make_option(
    "--usersetqdir"
    , type = "character"
    , default = "user_set_queries"
    , help = "The directory to place user set sql queries [default %default]"
  ),
  make_option(
    "--effthreshweek"
    , type = "numeric"
    , default = 26
    , help = "The number of weeks before the efficiency analysis cutoff
        [default %default]"
  ),
  make_option(
    "--sessqueryname"
    , type = "character"
    , default = "sess_dur_data"
    , help = "The name of the session duration query. [default %default]"
  ),
  make_option(
    "--effthreshpct"
    , type = "numeric"
    , default = 1
    , help = "The funds raised percentage cutoff for the efficiency analysis
        [default %default]"
  ),
  make_option(
    "--timeint"
    , type = "character"
    , default = "month"
    , help = "Wether to show active users by week or month [default %default]"
  )
)
