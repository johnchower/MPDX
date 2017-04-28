library(optparse)
option_list <- list(
  make_option(
    "--timeint" 
    , type = "character"
    , default = "month"
    , help = "Wether to show active users by week or month [default %default]"
  )
)
