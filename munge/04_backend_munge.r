proj_root <- rprojroot::find_root(rprojroot::has_dirname("mpdx"))

funds_vs_pas_all <- wide_data %>%
  calculate_pa_scatter_data %>%
  mutate(post_gloo = nst_session %in% c("1318", "1526", "2798"))

funds_vs_pas <- wide_data %>%
  filter(nst_session %in% c("1318", "1526", "2798")) %>%
  calculate_pa_scatter_data
