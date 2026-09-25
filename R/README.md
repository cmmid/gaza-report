### Quickstart

To prepare and analyse data:

**1. Save data** into `data/raw`

- `gaza_adult_weight_form1.csv`
- `gaza_adult_weight_form2.csv`

**2. Prepare the data and run the analysis.** Run `R/main.R`. It sources `R/clean.R` to build `data/processed/participants.csv` and `data/processed/data-quality.csv`, then renders `report/results.qmd`.

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

To run the clean step alone:

```
source(here::here("R", "clean.R"))
```

`report/results.qmd` is the analysis: data quality and exclusions, participant characteristics, change since pre-war, associations, recovery during follow-up, and the selection checks, in one document.
It filters to `record_remove == "include"`, writes `report/results.html` for review and `report/results.docx` for pasting into the manuscript draft, and saves the manuscript figures to `outputs/figures/` at print size.
It is not cached, and renders in under a minute.

Inference is frequentist: means and prevalences with 95% confidence intervals, `lm` for the associations, `glm` for who returns, and one `lmer` for BMI over calendar time.
