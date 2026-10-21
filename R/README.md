### Quickstart

To prepare and analyse data:

**1. Save data** into `data/raw`

- `gaza_adult_weight_form1.csv`
- `gaza_adult_weight_form2.csv`

**2. Prepare the data and run the analysis.** Run `R/main.R`. It sources `R/clean.R` to build `data/processed/participants.csv` and `data/processed/data-quality.csv`, then renders `report/manuscript.qmd` and `report/supplement.qmd`.

Note that for completeness, the data processing step keeps all recorded measurements (with duplicates, unidentified, etc).
Invalid records are described in the `record_remove` field, and any modified values recorded in `record_notes`.

- Weight data come from raw records across two ODK survey forms
  - `form1`: baseline enrolment record with all characteristics
  - `form2`: follow-up (date, weight measurement only)
- `R/clean.R` combines both forms into a single long dataset, `data/processed/participants.csv`
- All collected records are included in the data-processed csv, including invalid records or implausible values
  - Records are assessed against each exclusion criterion in turn
  - Reasons for exclusion are flagged in the field `record_remove`
  - Records passing all criteria are labelled `include`

`R/context.R` reads three tracked extracts: `data/raw/idb2025_gaza_pop_age_sex_2025.csv` (US Census Bureau International Database, projected mid-2025 population of the Gaza Strip by age and sex), used to standardise change since pre-war to adults in the Gaza Strip; `data/raw/ncdrisc_2026_bmi_age_sex_2022.csv` (NCD-RisC BMI estimates for Palestine and the world), used to check recalled pre-war BMI; and `data/raw/gaza_survey2020_kcal_bmi_agg.csv` (aggregate means from a 2020 survey of adults aged 40 and over), also used to check recalled pre-war BMI. To rebuild the first two, download the source files listed at the top of `R/ncdrisc-extract.R` into `data/context/` and run that script.

To run the clean step alone:

```
source(here::here("R", "clean.R"))
```

The analysis is split by topic. `R/utils.R` (packages, formatting helpers) and `R/data.R` (variable definitions, `included`, `baseline`) are sourced first; each topic file then runs on its own:

| File | Topic |
|---|---|
| `R/participation.R` | Participation and system performance: exclusions, unlinked follow-up, balance by cohort and follow-up, return for follow-up, timeliness |
| `R/prewar.R` | Change from pre-war to enrolment, underweight relative risk, risk factors (Table 1), chronic condition |
| `R/followup.R` | Longitudinal set, follow-up GAM, refit to participants spanning the ceasefire, paired change |
| `R/context.R` | Reference populations: standardisation to adults in the Gaza Strip, NCD-RisC, 2020 survey, published studies |

Each topic file has sections Set-up, Analysis, Supplementary analysis, and Numbers in the text. The last builds `numbers_<topic>`: each plain-text number in the qmds that no table shows, with its location. Inspect it after any change to the data or analysis.

`report/manuscript.qmd` sources utils, data, prewar and followup; `report/supplement.qmd` sources all of them.
Each renders to html and docx in `report/`, and saves its figures to `outputs/figures/` at print size.
Nothing is cached; a full run takes a few minutes, most of it the two 2000-resample bootstraps in `context.R`.

Inference is frequentist: means and prevalences with 95% confidence intervals, `lm` for the associations, `glm` for who returns, and a `mgcv::gam` with a participant random intercept for weight over calendar time.
