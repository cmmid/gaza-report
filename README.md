# Real-time signals of food insecurity: a co-designed cohort with humanitarian staff in the Gaza Strip, 2025

Code and aggregate data for the manuscript and its supplement.

- Manuscript: [report/manuscript.docx](report/manuscript.docx)
- Supplement: [report/supplement.docx](report/supplement.docx)

Both documents are rendered from the Quarto files in [report/](report/). Data cleaning was adapted from the study's public dashboard repository, <https://github.com/cmmid/gaza-response>.

## Data

Individual-level participant records are not in this repository, but held confidentially to reduce the risk of de-anonymisation in small samples.

The repository contains two aggregate or public files, in [data/raw/](data/raw/):

| File | Contents | Source |
|---|---|---|
| `gaza_survey2020_kcal_bmi_agg.csv` | Mean age, weight, height and energy intake by age band and sex, adults aged 40 and over | 2020 population survey in the Gaza Strip |
| `ncdrisc_2026_bmi_age_sex_2022.csv` | Modelled prevalence by BMI band and sex, 2022: Palestine by 5-year age group, world age-standardised | NCD-RisC, <https://www.ncdrisc.org/data-downloads-adiposity.html> |

[R/ncdrisc-extract.R](R/ncdrisc-extract.R) builds the NCD-RisC file from the downloaded source files.

## Results

Each analysis script in [R/](R/) ends with a `numbers_<topic>` table listing any numbers quoted in the text.

### Manuscript

| Item | Content | Built in |
|---|---|---|
| Figure 1 | Participant flow; weekly measurements | [R/participation.R](R/participation.R) (counts); drawn in [report/manuscript.qmd](report/manuscript.qmd) |
| Table 1 | Characteristics and weight change since pre-war, crude and adjusted | [R/prewar.R](R/prewar.R) |
| Figure 2A | BMI pre-war and at enrolment | [R/prewar.R](R/prewar.R) |
| Figure 2B | Weight trajectories over follow-up, with fitted GAM | [R/followup.R](R/followup.R) |
| Figure 3 | Adjusted differences in weight change since pre-war | [R/prewar.R](R/prewar.R) |

### Supplement

| Item | Content | Built in |
|---|---|---|
| Tables S1, S2 | Enrolment characteristics by cohort, and by follow-up | [R/participation.R](R/participation.R) |
| Table S3 | Odds of contributing a follow-up measurement | [R/participation.R](R/participation.R) |
| Table S4 | Change from pre-war to enrolment | [R/prewar.R](R/prewar.R) |
| Table S5 | Weight lost by pre-war BMI category | [R/prewar.R](R/prewar.R) |
| Table S6 | Chronic condition and weight change | [R/prewar.R](R/prewar.R) |
| Table S7 | Sensitivity of follow-up change to model and selection | [R/followup.R](R/followup.R) |
| Table S8 | Pre-war BMI against the 2020 survey | [R/context.R](R/context.R) |
| Table S9 | Pre-war underweight and obesity against NCD-RisC | [R/context.R](R/context.R) |
| Table S10 | Published studies of adult weight change in the Gaza Strip | [R/context.R](R/context.R) |
| Table S11 | STROBE checklist | [report/supplement.qmd](report/supplement.qmd) |
| Figure S1 | BMI category by age band and sex, pre-war and at enrolment | [R/prewar.R](R/prewar.R) |
| Figure S2 | Diagnostics for the follow-up model | [R/followup.R](R/followup.R) |

## Code

| File | Role |
|---|---|
| [R/main.R](R/main.R) | Runs the cleaning step, then renders the manuscript and supplement |
| [R/clean.R](R/clean.R) | Combines the two raw ODK forms (enrolment, follow-up) into one long dataset, one row per participant per measurement; flags each excluded record with its reason |
| [R/utils.R](R/utils.R), [R/data.R](R/data.R) | Shared helpers; variable labels; the analysis set |
| [R/participation.R](R/participation.R) | Exclusions, unlinked records, balance, return for follow-up |
| [R/prewar.R](R/prewar.R) | Change from pre-war to enrolment, underweight relative risk, risk factors |
| [R/followup.R](R/followup.R) | Longitudinal set, follow-up GAM, sensitivity refits |
| [R/context.R](R/context.R) | Comparisons with the 2020 survey, NCD-RisC and published studies |
| [report/gaza.bib](report/gaza.bib) | References |

Running the code requires the individual-level data; see [R/README.md](R/README.md).

## Other files

- [attic/protocol.docx](attic/protocol.docx): study protocol
- [attic/](attic/): earlier drafts and superseded analyses, not used in the manuscript

## Licence

Code: MIT ([LICENSE](LICENSE)).
