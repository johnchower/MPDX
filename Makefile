report_plus_csvs.zip: csvs.zip presentation.html
	mkdir report_plus_csvs; \
	unzip csvs.zip -d report_plus_csvs; \
	mv report_plus_csvs/csvs/* report_plus_csvs; \
	rm -rf report_plus_csvs/csvs; \
	mv presentation.html report_plus_csvs; \
	zip -r report_plus_csvs.zip report_plus_csvs

csvs.zip: dump_csvs.r mpd_stats_wide_3.csv
	mkdir csvs; \
	Rscript dump_csvs.r; \
	zip -r csvs.zip csvs

presentation.html: presentation_backend.r mpd_stats_wide_3.csv presentation.rmd retention_curve_functions.r user_sets.zip sess_dur_data.csv
	unzip user_sets.zip; \
	Rscript -e "rmarkdown::render('presentation.rmd', output_format = 'html_document', output_file = 'presentation.html')"; \
	rm -rf user_sets

USERQS = $(wildcard user_set_queries/*)
user_sets.zip: get_user_set_data.r user_set_queries $(USERQS)
	mkdir user_sets; \
	Rscript get_user_set_data.r; \
	zip -r user_sets.zip user_sets; \
	rm -rf user_sets

sess_dur_data.csv: get_sess_dur_data.r sess_dur_data.sql
	Rscript get_sess_dur_data.r

mpd_stats_wide_3.csv: clean_and_prep_data.r interpolate_goals.r mpd_stats.csv assessment_response.csv user_pacount_week.csv
	Rscript clean_and_prep_data.r

user_pacount_week.csv: get_user_pacount_week_csv.r user_pacount_week.sql
	Rscript get_user_pacount_week_csv.r

assessment_response.csv: get_assessment_query_csv.r assessment_query.sql
	Rscript get_assessment_query_csv.r

clean:
	rm -rf report_plus_csvs; \
	rm -rf csvs; \
	rm presentation.txt presentation.md

.PHONY: clean
