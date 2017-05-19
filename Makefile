# retention_curve_time_interval can be either "month" or "week"
LIB = $(wildcard lib/*)
MUNGE = $(wildcard munge/*)
DATA = $(wildcard data/*)
INPUTDATA = $(wildcard input_data/*)
USERSETS = $(wildcard data/user_set-*)
QUERIES = $(wildcard queries/*)
output_csv_directory := reports/csvs
retention_curve_time_interval := month
efficiency_analysis_threshold_week := 26
efficiency_analysis_threshold_pct := 1
user_set_query_directory := user_set_queries
user_set_result_directory := user_sets
sess_dur_data_query_name := sess_dur_data
auth_file := ~/.auth/authenticate
.DEFAULT_GOAL := reports/presentation.html

reports/presentation_plus_csvs.zip: reports/csvs.zip reports/presentation.html
	mkdir -p reports/presentation_plus_csvs; \
	cd reports ; \
	unzip csvs.zip -d presentation_plus_csvs; \
	mv presentation_plus_csvs/csvs/* presentation_plus_csvs; \
	rm -rf presentation_plus_csvs/csvs; \
	cp presentation.html presentation_plus_csvs; \
	zip -r presentation_plus_csvs.zip presentation_plus_csvs; \
	rm -rf presentation_plus_csvs

reports/csvs.zip: $(LIB) $(MUNGE) data.zip src/presentation_backend.r src/dump_csvs.r
	unzip data.zip; \
	mkdir -p $(output_csv_directory) ; \
	Rscript ./src/dump_csvs.r --output_csv_directory $(output_csv_directory) --timeint $(retention_curve_time_interval) --effthreshpct $(efficiency_analysis_threshold_pct) --effthreshweek $(efficiency_analysis_threshold_week); \
	rm -rf data; \
	cd reports ; \
	zip -r csvs.zip csvs ; \
	rm -rf csvs ; \

reports/presentation.html: $(LIB) $(MUNGE) data.zip src/presentation_backend.r 
	unzip data.zip; \
	Rscript -e 'rmarkdown::render("presentation.rmd", output_format = "html_document", output_file = "presentation.html", params = list(timeint = "$(retention_curve_time_interval)", effthreshweek = $(efficiency_analysis_threshold_week), effthreshpct = $(efficiency_analysis_threshold_pct)))'; \
	rm -rf data ; \
	mkdir -p reports; \
	mv presentation.html reports/ ; \

data.zip: $(QUERIES) $(INPUTDATA) src/run_queries.r
	mkdir -p data; \
	cp input_data/* data/ ;\
	Rscript ./src/run_queries.r --auth_file_location $(auth_file) ; \
	zip -r data.zip data; \
	rm -rf data

mkfileViz.png: makefile2dot.py Makefile
	python makefile2dot.py <Makefile |dot -Tpng > mkfileViz.png

clean: 
	rm data.zip ; \
	rm -rf data ; \
	rm reports/csvs.zip ; \

.PHONY: clean
