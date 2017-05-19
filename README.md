# mpdx

This is the code that produces the Cru MPDX analysis.

## How to use:
1. Download the code
2. If you have SQL access to the data warehouse, copy the auth file template
   and enter your credentials.
3. If you don't have SQL access to the data warehouse, but you have Looker,
   paste the queries found in "queries" directory into your SQL runner and
   download the results as csvs. Rename the csvs according to the name of the
   corresponding query (so for example sess_dur_data.sql becomes
   sess_dur_data.csv) and place the resulting csvs into the "input_data"
   directory.
4. The first time you run the code, you'll have to install the required R
   packages into the packrat directory. This can be done simply by typing the
   command `Rscript -e "packrat::restore()"`. This will take some time.
5. Once `packrat::restore()` has been run, you're good to go. Just run the
   command `make` and wait. The process should only take a couple of minutes.

## How to read:

This project uses the [ ProjectTemplate ](http://projecttemplate.net/index.html) 
package to structure and control the workflow.

In addition, there are naming conventions for functions and datasets.

In addition, we use [ GNU Make ](https://www.gnu.org/software/make/) to build 
the final outputs.

In addition we use packrat to freeze R packages and ensure reproducibility down
the line.
