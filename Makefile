report_plus_csvs.zip: presentation.html dump_csvs.r mpd_stats_wide_3.csv retention_curve.csv retention_curve.png
	mkdir report_plus_csvs; \
	cp presentation.html report_plus_csvs; \
	cp retention_curve.csv report_plus_csvs; \
	cp retention_curve.png report_plus_csvs; \
	Rscript dump_csvs.r; \
	zip -r report_plus_csvs.zip report_plus_csvs; \
	rm -rf report_plus_csvs

presentation.html: presentation_backend.r mpd_stats_wide_3.csv presentation.rmd 
	Rscript -e "rmarkdown::render('presentation.rmd', output_format = 'html_document', output_file = 'presentation.html')"

mpd_stats_wide_3.csv: clean_and_prep_data.r user_pacount_week.sql assessment_query.sql interpolate_goals.r mpd_stats.csv
	Rscript clean_and_prep_data.r
