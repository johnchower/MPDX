# retention_curve_time_interval can be either "month" or "week"
DATA = $(wildcard data/*)
INPUTDATA = $(wildcard input_data/*)
USERSETS = $(wildcard data/user_set-*)
QUERIES = $(wildcard queries/*)
retention_curve_time_interval := month
efficiency_analysis_threshold_week := 26
efficiency_analysis_threshold_pct := 1
user_set_query_directory := user_set_queries
user_set_result_directory := user_sets
sess_dur_data_query_name := sess_dur_data
auth_file := ~/.auth/authenticate
.DEFAULT_GOAL := reports/presentation.html

# reports/csvs.zip: src/presentation_backend.r lib/retention_curve_functions.r lib/presentation_functions.r data.zip munge.zip

reports/presentation.html: src/presentation_backend.r src/presentation.rmd lib/retention_curve_functions.r lib/presentation_functions.r data.zip munge.zip

data.zip: $(QUERIES) src/run_queries.r $(INPUTDATA)
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


.PHONY: clean data_directory
