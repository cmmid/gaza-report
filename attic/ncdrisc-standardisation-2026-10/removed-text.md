<!-- Superseded 2026-10-13. Removed from report/manuscript.qmd and report/supplement.qmd. -->

## manuscript.qmd setup helpers

```r
# One value from the standardisation (Table S11), by target and column
standardised <- function(target, column) {
  underweight_standardised[[column]][underweight_standardised$target == target]
}

# "estimate% (low to high)" for one bound of the standardisation
standardised_ci <- function(target, bound) {
  paste0(
    fmt_pct(standardised(target, bound)),
    sprintf(
      " (%.1f to %.1f)",
      standardised(target, paste0(bound, "_low")),
      standardised(target, paste0(bound, "_high"))
    )
  )
}
```

## manuscript.qmd Methods

<!-- SCAFFOLD: methods, reference standardisation -->

- Question: underweight among adults in Palestine, if they had lost what participants of the same sex and age lost.
- Reference pre-war BMI: NCD-RisC modelled BMI band prevalences for Palestine, 2022, by sex and 5-year age group [@ncdriscObesityRisePlateaus2026].
  2022 precedes the war; the estimate includes the West Bank.
- Population weights: Palestine, 1 July 2023, by sex and 5-year age group [@unWorldPopulationProspects2024].
  Ages `r population_ages[1]`-`r population_ages[2]`; participants were aged `r min(standard_set$age_years)`-`r max(standard_set$age_years)`.
- Data sources: NCD-RisC adult BMI files `NCD_RisC_Nature_2026_BMI_{female,male}_age_specific_country` (downloaded 10 October 2026) and `NCD_RisC_Nature_2026_BMI_age_standardised_world` (12 October 2026) from ncdrisc.org, point estimates only; `WPP2024_PopulationByAge5GroupSex_Medium` (12 October 2026) from population.un.org.
  Extraction in `attic/ncdrisc-extract.R`.
- Reference CDF: monotone spline through cumulative band prevalences on log BMI, exact at NCD-RisC cut-points.
- Losses: each sex and 5-year age group of the reference takes the losses of participants of the same sex and age category (under 30, 30-45, over 45).
- Rationale: population BMI distributions shift as a whole, so the reference distribution determines the share crossing a threshold [@rosePopulationMeanPredicts1990].
- Two bounds.
  Upper: each participant's observed log ratio applied unchanged.
  Lower: loss scaled by pre-war BMI with the slope from `log ratio ~ log pre-war BMI + age + sex`, keeping each participant's residual.
- Check: the same reference weighted to participants' age and sex, against recalled pre-war obesity and observed underweight.
- Comparison: the world's pre-war BMI by sex, age-standardised (NCD-RisC 2022), with the losses of all participants of that sex.
- 95% intervals: 2000 bootstrap resamples of participants, reference distributions and population weights fixed.
  `r nrow(baseline) - nrow(standard_set)` participants without age excluded (n = `r nrow(standard_set)`).

## manuscript.qmd Results

<!-- SCAFFOLD: results, underweight standardised to the adult population (Table S11) -->

- Observed among participants: `r fmt_pct(100 * mean(standard_set$bmi_prewar < 18.5))` underweight pre-war, `r fmt_pct(100 * mean(standard_set$bmi_entry < 18.5))` at enrolment.
- Adults aged `r population_ages[1]`-`r population_ages[2]` in Palestine: `r fmt_pct(standardised("population", "underweight_prewar"))` underweight and `r fmt_pct(standardised("population", "obese_prewar"))` obese pre-war (NCD-RisC 2022).
  With participants' losses: `r standardised_ci("population", "underweight_b")` (lower bound) to `r standardised_ci("population", "underweight_a")` (upper bound) underweight.
- Check, same reference weighted to participants' age and sex: 37.7% obese pre-war vs `r fmt_pct(100 * mean(standard_set$bmi_prewar >= 30))` from recalled weight.
  Women: `r sprintf("%.0f%%", palestine_obese_by_sex$obese_recalled[palestine_obese_by_sex$sex == "Female"])` recalled vs 45% reference obese; men: `r sprintf("%.0f%%", palestine_obese_by_sex$obese_recalled[palestine_obese_by_sex$sex == "Male"])` vs 29%.
  Underweight at enrolment `r standardised_ci("study", "underweight_b")` to `r standardised_ci("study", "underweight_a")`, above the `r fmt_pct(100 * mean(standard_set$bmi_entry < 18.5))` observed.
- Comparison, same losses from the world's pre-war BMI (`r fmt_pct(standardised("world", "obese_prewar"))` obese): `r standardised_ci("world", "underweight_b")` to `r standardised_ci("world", "underweight_a")` underweight.

## manuscript.qmd Discussion

<!-- SCAFFOLD: discussion, reference standardisation (Table S11) -->

- Underweight among participants understates the adult population: the reference population was leaner pre-war than participants, with more adults close to BMI 18.5.
- WHO grades adult underweight prevalence ≥20% as high and ≥40% as very high public health significance [@whoPhysicalStatusUse1995; @ferro-luzziAdultMalnutritionSimple1996].
  Check exact TRS 854 wording.
- Assumes adults in the population lost what staff of the same sex and age lost.
  Salary and proximity to aid: staff lost less, estimate too low.
  Those who lost most chose to take part: estimate too high.
- The check does not reproduce observed underweight, despite matching pre-war obesity.
  Reference men are leaner than participating men and men lost more; reference prevalence below BMI 18.5 is interpolated.
- Overall obesity match hides offsetting sex differences.
- Same direction as the 2020 survey (Table S10): women leaner, men heavier than the population.
  Under-recall by women and over-recall by men, or staff differing from the population (selection), or both.
  Not separable here.
  NCD-RisC Palestine includes the West Bank and is modelled.
- World comparison: the same losses from a typical pre-war BMI distribution would leave around a third of adults underweight; high pre-war BMI masked the scale of loss.
- Caveats: lower bound extrapolates the BMI gradient below BMI 20, where few participants sit; does not model physiology of lean people (more lean-tissue loss as fat stores deplete).
  This converges in support of the IPC analysis of famine.

## supplement.qmd Table S11

## Underweight under reference pre-war BMI distributions

```{r}
#| label: tbl-underweight-standardised
#| tbl-cap: >-
#|   Underweight (BMI < 18.5 kg/m2) at enrolment if each reference population had lost the weight that participants of the same sex and age category lost.
#|   Reference distributions are NCD-RisC estimates of pre-war BMI for 2022: Palestine by sex and 5-year age group, weighted to its population in 2023 (UN World Population Prospects 2024) or to participants' age and sex, and the world by sex, age-standardised.
#|   Lower: loss scaled by pre-war BMI through the gradient observed in this study.
#|   Upper: each participant's observed proportional loss, regardless of pre-war BMI.
#|   95% intervals from 2000 bootstrap resamples of participants, with reference distributions and population weights held fixed.

bind_rows(
  tibble(
    `Reference population` = "This study (observed)",
    `Pre-war underweight, %` = sprintf("%.1f", 100 * mean(standard_set$bmi_prewar < 18.5)),
    `Pre-war obese, %` = sprintf("%.1f", 100 * mean(standard_set$bmi_prewar >= 30)),
    `Underweight at enrolment, %, lower` = sprintf("%.1f", 100 * mean(standard_set$bmi_entry < 18.5)),
    `Underweight at enrolment, %, upper` = ""
  ),
  underweight_standardised |>
    transmute(
      `Reference population` = reference,
      `Pre-war underweight, %` = sprintf("%.1f", underweight_prewar),
      `Pre-war obese, %` = sprintf("%.1f", obese_prewar),
      `Underweight at enrolment, %, lower` = fmt_ci(
        underweight_b, underweight_b_low, underweight_b_high
      ),
      `Underweight at enrolment, %, upper` = fmt_ci(
        underweight_a, underweight_a_low, underweight_a_high
      )
    )
) |>
  ft()
