# Do Animals Matter? The Value of Animal Welfare Information to Consumers

Data and code for the paper by Cass R. Sunstein, Micha A. Kaiser, Piotr Lipinski and Lucia A. Reisch.

Pre-registration and survey materials: <https://osf.io/ev5w8>

## Contents

| File | Description |
|---|---|
| `data/merged_data.dta` | Survey data, pooled over the six countries (Denmark, France, Germany, Netherlands, UK, US). One row per respondent, 6,557 respondents. |
| `data/buying_frequencies.xlsx` | Purchase frequencies per buyer and year by country and product category, with sources. |
| `analysis.do` | Stata code for the tables and figures, and for the inputs to the welfare calculation. |
| `welfare_figures.py` | Python code for the welfare calculation (Section 5.4). |

## Running the code

1. Install the user-written Stata packages: `ssc install estout`, `ssc install coefplot`, `ssc install cibar`, `ssc install blindschemes`.
2. Start Stata in the repository folder (or set `global root` at the top of `analysis.do`) and run `do analysis.do`. Output is written to `output/`.
3. Run `python welfare_figures.py`. It reads the files that `analysis.do` writes to `output/welfare/` and writes to `output/welfare/out/`.

Stata 18 or newer is required (`dtable`); the results in the paper were produced with StataNow 19.5. `analysis.do` takes about 20 minutes with Stata/MP on four cores, most of it for the margins grids and the bootstrap. The Python script needs `numpy`, `pandas`, `matplotlib` and `openpyxl`.

## Data

The survey data were collected by YouGov between 18 and 25 May 2026. `merged_data.dta` contains the files delivered by YouGov for each country, appended, with the following variables added:

- `country`
- `income_quartile`: household income group; the top two of five groups are combined (Germany was delivered in four groups)
- `married`: married or in a civil partnership
- `workfulltime`: working full time
- `labelscore`: number of real animal-welfare labels recognised minus number of fake labels marked as real
- `PRICE1x_euros` to `PRICE8x_euros`: recalled prices in euros (7.47 DKK, 0.86 GBP and 1.16 USD per euro)

The open-text comment field at the end of the survey has been removed. All other variables are as delivered.

The product categories are numbered 1 meat, 2 eggs, 3 milk, 4 fur, 5 leather, 6 cosmetics, 7 pet food, 8 over-the-counter medicine.

## Output

| Paper | File in `output/` |
|---|---|
| Figure 2 | `wtk_categories.png` |
| Figure 3 | means by product in `D4_wtp_product.png`, `D4_wtp_product_absolute.png`, `D5_wtpn_product.png` |
| Figure 4 | `wtk_predictions.png`, `cp_h1h3_combined.png` |
| Figure 5 | `cond_wtk.png`, `cond_wtp.png`, `cond_wtpn.png` |
| Figure 6 | `cp_h4.png` |
| Figure 7 | `D_wtk_product_sorted.png` |
| Figure 8 | `cp_h6.png` |
| Figure 9 | `welfare/out/fig1_welfare_by_category_ci.png` |
| Figure 10 | `welfare/out/fig2_welfare_by_country_ci.png` |
| Figure 11 | `welfare/out/fig3_welfare_contour.png` |
| Figures A1, A2 | `D8_wtp_country.png`, `D9_wtpn_country.png` |
| Figure A3 | `cp_h5.png` |
| Figure A4 | `contour/wtk_contour_lowhigh.png` |
| Figure A5 | `welfare/out/figA3_welfare_contour_by_product.png` |
| Table A1 | `Table_D_descriptives.docx` |
| Table A2 | `sem` output in the log |
| Table A3 | `wtk_results.rtf` |
| Tables A4, A5 | `wtp_prct_results.rtf`, `wtpn_prct_results.rtf` |
| Tables A6, A7 | `wtp_log_results.rtf`, `wtpn_log_results.rtf` |
| Table A8 | `welfare/out/tableA_welfare_inputs.csv` |
| Table A9 | `welfare/out/tableB_welfare_aggregates.csv`, `welfare/out/tableC_welfare_bootstrap_ci.csv` |
| Tables A10 to A12 | `wtk_country_results.rtf`, `wtp_prct_country_results.rtf`, `wtpn_prct_country_results.rtf` |
| Table A13 | `standardized_results.rtf` |
| Table A14 | `R3_5_interactions.rtf` |
