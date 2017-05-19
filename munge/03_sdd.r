sdd.sess_dur_data <- sess.dur.data %>%
  mutate(active_month_start_date = as.Date(active_month_start_date))

rm(sess.dur.data)
