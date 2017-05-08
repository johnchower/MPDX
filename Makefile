# retention_curve_time_interval can be either "month" or "week"
retention_curve_time_interval := month
efficiency_analysis_threshold_week := 26
efficiency_analysis_threshold_pct := 1
user_set_query_directory := user_set_queries
user_set_result_directory := user_sets
sess_dur_data_query_name := sess_dur_data

report_plus_csvs.zip: csvs.zip presentation.html
	mkdir report_plus_csvs; \
	unzip csvs.zip -d report_plus_csvs; \
	mv report_plus_csvs/csvs/* report_plus_csvs; \
	rm -rf report_plus_csvs/csvs; \
	cp presentation.html report_plus_csvs; \
	zip -r report_plus_csvs.zip report_plus_csvs; \
	rm -rf report_plus_csvs

csvs.zip: presentation_backend.r dump_csvs.r mpd_stats_wide_3.csv presentation_functions.r $(user_set_result_directory).zip $(sess_dur_data_query_name).csv
	unzip $(user_set_result_directory).zip; \
	mkdir csvs; \
	Rscript dump_csvs.r --timeint $(retention_curve_time_interval) --usersetcsvdir $(user_set_result_directory) --sessqueryname $(sess_dur_data_query_name) --effthreshpct $(efficiency_analysis_threshold_pct) --effthreshweek $(efficiency_analysis_threshold_week); \
	rm -rf $(user_set_result_directory); \
	zip -r csvs.zip csvs; \
	rm -rf csvs

presentation.html: presentation_backend.r mpd_stats_wide_3.csv presentation.rmd retention_curve_functions.r $(user_set_result_directory).zip $(sess_dur_data_query_name).csv presentation_functions.r
	unzip $(user_set_result_directory).zip; \
	# Add parameters to the render function call
	Rscript -e 'rmarkdown::render("presentation.rmd", output_format = "html_document", output_file = "presentation.html", params = list(timeint = "$(retention_curve_time_interval)", sessqueryname = "$(sess_dur_data_query_name)", usersetcsvdir = "$(user_set_result_directory)", effthreshweek = $(efficiency_analysis_threshold_week), effthreshpct = $(efficiency_analysis_threshold_pct)))'; \
	rm -rf $(user_set_result_directory)

USERQS = $(wildcard $(user_set_query_directory)/*)

$(user_set_result_directory).zip: get_user_set_data.r $(user_set_query_directory) $(USERQS) option_list.r
	mkdir $(user_set_result_directory); \
	Rscript get_user_set_data.r --timeint $(retention_curve_time_interval) --usersetqdir $(user_set_query_directory) --usersetcsvdir $(user_set_result_directory); \
	zip -r $(user_set_result_directory).zip $(user_set_result_directory); \
	rm -rf $(user_set_result_directory)

$(sess_dur_data_query_name).csv: get_sess_dur_data.r $(sess_dur_data_query_name).sql
	Rscript get_sess_dur_data.r --timeint $(retention_curve_time_interval) --sessqueryname $(sess_dur_data_query_name)

mpd_stats_wide_3.csv: clean_and_prep_data.r interpolate_goals.r mpd_stats.csv assessment_response.csv user_pacount_week.csv
	Rscript clean_and_prep_data.r

user_pacount_week.csv: get_user_pacount_week_csv.r user_pacount_week.sql
	Rscript get_user_pacount_week_csv.r

assessment_response.csv: get_assessment_query_csv.r assessment_query.sql
	Rscript get_assessment_query_csv.r

csv_inputs: assessment_response.csv user_pacount_week.csv mpd_stats_wide_3.csv $(sess_dur_data_query_name).csv $(user_set_result_directory).zip

start_over:
	rm -rf report_plus_csvs; \
	rm -rf csvs; \
	rm $(sess_dur_data_query_name).csv; \
	rm $(user_set_result_directory).zip; \
	rm presentation.txt presentation.md Rplots.pdf presentation.html csvs.zip; \
	rm user_pacount_week.csv report_plus_csvs.zip mpd_stats_wide_3.csv assessment_response.csv

.PHONY: start_over csv_inputs
