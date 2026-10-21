# =============================================================================
# Weight change from pre-war (recalled, October 2023) to enrolment (measured,
# 2025): change, underweight, and associations with participant characteristics.
# Manuscript: Results "Weight change over the conflict", Table 1, Figures 2A and 3
# Supplement: "Change over conflict period", "Risk factors for weight change
#   since pre-war"
# Sourced after R/utils.R and R/data.R.
# =============================================================================

# Set-up ----------------------------------------------------------------------
pacman::p_load(contingencytables)

exposures <- c(
  "age",
  "sex",
  "governorate_cat",
  "children",
  "role_cat",
  "organisation",
  "entry_cohort"
)

# Reference level = first level of each characteristic (age under 30), except
# governorate, where the reference is the most populated stratum.
governorate_ref <- "Khan Yunis, Rafah"
model_data <- baseline |>
  mutate(
    governorate_cat = relevel(governorate_cat, ref = governorate_ref)
  )

# Participants with a pre-war BMI category and a measured weight at enrolment
loss_set <- baseline |>
  filter(!is.na(bmi_category_prewar), !is.na(weight_entry)) |>
  mutate(
    kg_lost = weight_prewar - weight_entry,
    pct_lost = -pct_weight_change,
    bmi_category_prewar = factor(bmi_category_prewar, levels = bmi_levels)
  )

# Estimate and CI in one column: "estimate (low to high)". Rows without a CI
# (reference levels, model summaries) are left as they are.
merge_ci <- function(tbl) {
  tbl |>
    modify_column_merge(
      pattern = "{estimate} ({conf.low} to {conf.high})",
      rows = !is.na(conf.low)
    ) |>
    modify_header(estimate = "**% difference (95% CI)**")
}

# Coefficients of lm() on the log weight ratio, back-transformed to the
# percentage difference in weight relative to the reference level
tbl_assoc <- function(fit, include = everything()) {
  tbl_regression(
    fit,
    include = {{ include }},
    label = labels_for(intersect(
      names(variable_labels),
      all.vars(formula(fit))
    )),
    tidy_fun = tidy_pct,
    estimate_fun = label_style_number(digits = 1)
  ) |>
    modify_column_hide("p.value") |>
    merge_ci()
}

# Analysis --------------------------------------------------------------------

## Change from pre-war to enrolment (tbl-headline) ----
# Mean change with t-based 95% CI, overall and by cohort
tbl_change <- baseline |>
  select(entry_cohort, pct_weight_change, bmi_change) |>
  tbl_summary(
    by = entry_cohort,
    label = labels_for(c("pct_weight_change", "bmi_change")),
    statistic = all_continuous() ~ "{mean}",
    digits = list(pct_weight_change ~ 1, bmi_change ~ 2),
    missing = "no"
  ) |>
  add_overall() |>
  add_ci(
    method = all_continuous() ~ "t.test",
    statistic = ci_statistic,
    style_fun = list(
      pct_weight_change ~ label_style_number(digits = 1),
      bmi_change ~ label_style_number(digits = 2)
    ),
    pattern = "{stat} ({ci})"
  )

mean_loss <- t.test(-baseline$pct_weight_change)

## Underweight at enrolment vs pre-war ----
# Relative risk: the same participants are counted twice, so the interval is
# Wald for a ratio of paired proportions. Rows are enrolment, columns pre-war,
# so the estimate is enrolment / pre-war.
paired_underweight <- baseline |>
  filter(!is.na(underweight_prewar), !is.na(underweight_entry))
underweight_rr <- table(
  entry = factor(paired_underweight$underweight_entry, levels = c(TRUE, FALSE)),
  prewar = factor(paired_underweight$underweight_prewar, levels = c(TRUE, FALSE))
) |>
  unclass() |>
  Wald_CI_ratio_paired_2x2()

## Risk factors for weight loss since pre-war (tbl-characteristics) ----
tbl_characteristics <- model_data |>
  select(all_of(characteristic_order)) |>
  tbl_summary(
    label = labels_for(characteristic_order),
    statistic = all_categorical() ~ "{n} ({p}%)",
    digits = all_categorical() ~ c(0, 1),
    missing_text = "(Missing)"
  ) |>
  modify_header(stat_0 = "**N (%)**")

tbl_crude <- model_data |>
  select(log_weight_ratio, all_of(characteristic_order)) |>
  tbl_uvregression(
    method = lm,
    y = log_weight_ratio,
    label = labels_for(characteristic_order),
    tidy_fun = tidy_pct,
    estimate_fun = label_style_number(digits = 1),
    hide_n = TRUE
  ) |>
  modify_column_hide("p.value") |>
  merge_ci()

fit_adjusted <- lm(
  reformulate(exposures, response = "log_weight_ratio"),
  data = model_data
)
tbl_adjusted <- tbl_assoc(fit_adjusted)

# Table 1: characteristics with crude and adjusted associations.
# Chronic condition is in the crude model only
tbl_table1 <- tbl_merge(
  list(tbl_characteristics, tbl_crude, tbl_adjusted),
  tab_spanner = FALSE
) |>
  modify_header(
    estimate_2 = "**Crude % difference (95% CI)**",
    estimate_3 = "**Adjusted % difference (95% CI)**"
  )

## Chronic condition (tbl-chronic) ----
# Asked of a subset only, so it is adjusted separately, within those asked.
# All of them were UNRWA staff, so organisation drops out.
tbl_chronic <- tbl_assoc(
  lm(
    reformulate(
      c(setdiff(exposures, "organisation"), "chronic"),
      response = "log_weight_ratio"
    ),
    data = filter(model_data, !is.na(chronic))
  ),
  include = chronic
) |>
  add_glance_table(include = nobs)

# Supplementary analysis ------------------------------------------------------

## Weight loss by pre-war BMI (tbl-loss-by-bmi) ----
tbl_loss_by_bmi <- loss_set |>
  select(bmi_category_prewar, kg_lost, pct_lost, underweight_entry) |>
  tbl_summary(
    by = bmi_category_prewar,
    label = list(
      kg_lost ~ "Weight lost, kg",
      pct_lost ~ "Weight lost, % of pre-war",
      underweight_entry ~ "Underweight at enrolment"
    ),
    statistic = list(
      all_continuous() ~ "{mean}",
      all_dichotomous() ~ "{n} / {N}"
    ),
    digits = all_continuous() ~ 1,
    missing = "no"
  ) |>
  add_ci(
    include = c(kg_lost, pct_lost),
    method = all_continuous() ~ "t.test",
    statistic = ci_statistic,
    style_fun = all_continuous() ~ label_style_number(digits = 1),
    pattern = "{stat} ({ci})"
  )

# Participants overweight or obese before the war, and their loss
loss_overweight <- loss_set |>
  summarise(
    pct_overweight = 100 * mean(bmi_category_prewar %in% c("Overweight", "Obese")),
    pct_lost = mean(pct_lost[bmi_category_prewar %in% c("Overweight", "Obese")]),
    kg_lost = mean(kg_lost[bmi_category_prewar %in% c("Overweight", "Obese")])
  )

## Adjusted associations (fig-risk-factors) ----
# The adjusted model of Table 1, one row per level with reference levels at 0
adjusted_estimates <- tidy_plus_plus(
  fit_adjusted,
  tidy_fun = tidy_pct,
  variable_labels = labels_for(exposures)
) |>
  filter(!is.na(variable)) |>
  mutate(
    across(c(estimate, conf.low, conf.high), \(x) if_else(reference_row %in% TRUE, 0, x)),
    var_label = factor(var_label, levels = unique(var_label))
  ) |>
  select(var_label, label, reference_row, estimate, conf.low, conf.high)

## BMI category, pre-war and at enrolment (fig-bmi-pyramid) ----
bmi_category_long <- baseline |>
  select(
    id,
    sex,
    age,
    `Pre-war` = bmi_category_prewar,
    `Enrolment` = bmi_category_entry
  ) |>
  pivot_longer(
    c(`Pre-war`, `Enrolment`),
    names_to = "period",
    values_to = "bmi_category"
  ) |>
  filter(!is.na(bmi_category)) |>
  mutate(
    period = factor(period, levels = c("Pre-war", "Enrolment")),
    bmi_category = factor(bmi_category, levels = bmi_levels)
  )

## Mean, median and geometric mean (tbl-centre-comparison) ----
centres_prewar <- bind_rows(
  tibble(
    location = "Abstract; Plain summary; Results, change over the conflict",
    quantity = weight_label,
    group = "All participants",
    n = nrow(baseline),
    centres = list(weight_centres(baseline))
  ),
  tibble(
    location = "Results, change over the conflict",
    quantity = "BMI change, kg/m2",
    group = "All participants",
    n = sum(!is.na(baseline$bmi_change)),
    centres = list(centre_summary(baseline$bmi_change)),
    digits = 2
  ),
  baseline |>
    filter(!is.na(entry_cohort)) |>
    group_by(group = paste(entry_cohort, "cohort")) |>
    summarise(n = n(), centres = list(weight_centres(pick(everything())))) |>
    mutate(location = "Results, change over the conflict", quantity = weight_label)
)

# Numbers in the text ---------------------------------------------------------
numbers_prewar <- tribble(
  ~location, ~quantity, ~value,
  "Abstract; Results, change over the conflict", "Lost weight since pre-war",
  fmt_pct(100 * mean(baseline$pct_weight_change < 0), 1),
  "Abstract; Plain summary", "Mean weight lost, % of pre-war (95% CI)",
  sprintf("%.1f%% (%.1f to %.1f)", mean_loss$estimate,
          mean_loss$conf.int[1], mean_loss$conf.int[2]),
  "Results, change over the conflict", "Underweight pre-war; at enrolment",
  paste(
    sprintf("%.1f%% (%d/%d)", 100 * mean(paired_underweight$underweight_prewar),
            sum(paired_underweight$underweight_prewar), nrow(paired_underweight)),
    sprintf("%.1f%% (%d/%d)", 100 * mean(paired_underweight$underweight_entry),
            sum(paired_underweight$underweight_entry), nrow(paired_underweight)),
    sep = "; "
  ),
  "Results, change over the conflict", "Relative risk of underweight (95% CI)",
  fmt_ci(underweight_rr$estimate, underweight_rr$lower, underweight_rr$upper),
  "Results, change over the conflict", "Overweight or obese pre-war; their mean loss, % and kg",
  sprintf("%.0f%%; %.1f%%; %.1f kg", loss_overweight$pct_overweight,
          loss_overweight$pct_lost, loss_overweight$kg_lost),
  "Results, change over the conflict; Supplement, chronic condition", "Participants asked about chronic conditions",
  as.character(sum(!is.na(baseline$chronic)))
)
