# =============================================================================
# Participation and selection checks
# Manuscript: Results "Participation", "Sensitivity analysis"; Figure 1
# Supplement: "Participation and data collection"
# Source after R/utils.R and R/data.R
# =============================================================================

# Set-up ----------------------------------------------------------------------
pacman::p_load(broom)

# Recruitment advertisements
advert_dates <- as_date(c("2025-07-25", "2025-10-19"))

# Helper to count records and participants through each exclusion step
n_exclusion <- function(label, column = "n_records") {
  exclusions[[column]][exclusions$record_remove == label]
}

# Analysis --------------------------------------------------------------------

## Records and exclusions (fig-ppt A) ----
n_records_total <- n_exclusion("invalid_nonconsent", "n_remaining") +
  n_exclusion("invalid_nonconsent")
n_ids_total <- n_exclusion("invalid_nonconsent", "n_participants_remaining") +
  n_exclusion("invalid_nonconsent", "n_participants")

## Unlinked follow-up measurements (supplement text, fig-ppt B) ----
# Follow-up measurements, linked or not to an enrolment record
followup_weights <- data_processed |>
  filter(
    record_remove %in% c("include", "invalid_no_baseline"),
    is.na(record_number) | record_number > 1,
    !is.na(weight)
  ) |>
  mutate(
    linkage = if_else(
      record_remove == "include",
      "Linked to enrolment",
      "Not linked to enrolment"
    ),
    epiweek_record = epiweek(record_date)
  )

followup_median_weight <- followup_weights |>
  group_by(record_remove) |>
  summarise(median = median(weight)) |>
  tibble::deframe()

## Representativeness within the sample (tab-balance-cohort, tab-balance-followup) ----
# Enrolment characteristics by group, for selection checks
balance_vars <- c(
  "age",
  "sex",
  "governorate_cat",
  "children",
  "role_cat",
  "age_years",
  "bmi_prewar",
  "bmi_entry",
  "pct_weight_change"
)

balance_table <- function(data, group_var) {
  data |>
    filter(!is.na(.data[[group_var]])) |>
    select(all_of(c(group_var, balance_vars))) |>
    tbl_summary(
      by = all_of(group_var),
      label = labels_for(balance_vars),
      statistic = list(
        all_continuous() ~ "{mean} ({sd})",
        all_categorical() ~ "{n} ({p}%)"
      ),
      digits = list(all_continuous() ~ 1, all_categorical() ~ c(0, 1)),
      missing_text = "(Missing)"
    )
}

tbl_balance_cohort <- balance_table(baseline, "entry_cohort")

tbl_balance_followup <- baseline |>
  mutate(
    followup = factor(
      if_else(has_followup, "2+ measurements", "Single measurement"),
      levels = c("Single measurement", "2+ measurements")
    )
  ) |>
  balance_table("followup")

## Return for follow-up (tab-return) ----
# Odds of contributing any follow-up measurement
return_vars <- c(
  "age",
  "sex",
  "governorate_cat",
  "children",
  "role_cat",
  "bmi_entry",
  "entry_cohort"
)
fit_return <- glm(
  reformulate(return_vars, response = "has_followup"),
  data = baseline,
  family = binomial()
)

return_or <- tidy(fit_return, exponentiate = TRUE, conf.int = TRUE)
or_ci <- function(term) {
  row <- return_or[return_or$term == term, ]
  fmt_ci(row$estimate, row$conf.low, row$conf.high, 2)
}

## Weekly measurements (fig-ppt B) ----
# Weekly measurements by type, including follow-ups excluded as unlinked
weekly_measurements <- bind_rows(
  included |>
    transmute(
      record_date,
      type = if_else(record_number == 1, "Enrolment", "Follow-up, linked")
    ),
  followup_weights |>
    filter(record_remove == "invalid_no_baseline") |>
    transmute(
      record_date = as_date(record_date),
      type = "Follow-up, unlinked (excluded)"
    )
) |>
  mutate(
    week = floor_date(record_date, "week", week_start = 1),
    type = factor(
      type,
      levels = c(
        "Follow-up, unlinked (excluded)",
        "Follow-up, linked",
        "Enrolment"
      )
    )
  ) |>
  count(week, type)

system_events <- tibble(
  date = c(advert_dates, ceasefire_date),
  label = c(
    "Advertised",
    "Re-advertised",
    "Ceasefire"
  )
)

# Participant flow: counts for each box of the flow diagram
n_followup <- sum(baseline$has_followup)
n_excluded_values <- sum(exclusions$n_records[
  exclusions$record_remove %in%
    c(
      "invalid_missing",
      "invalid_no_prewar",
      "invalid_anomaly_weight",
      "invalid_anomaly_height",
      "invalid_anomaly_bmi",
      "invalid_anomaly_rate"
    )
])
fmt_n <- function(x) format(x, big.mark = ",")
flow_text <- list(
  received = sprintf(
    "Records received\n%s records from %s participant IDs",
    fmt_n(n_records_total),
    fmt_n(n_ids_total)
  ),
  excluded = paste0(
    sprintf("Records excluded: %s\n", fmt_n(n_records_total - nrow(included))),
    sprintf("- No consent: %d\n", n_exclusion("invalid_nonconsent")),
    sprintf(
      "- Follow-up matching no enrolment: %d\n",
      n_exclusion("invalid_no_baseline")
    ),
    sprintf(
      "- Duplicate, same participant and day: %d\n",
      n_exclusion("invalid_double_entry")
    ),
    sprintf("- Missing or implausible value: %d", n_excluded_values)
  ),
  enrolled = sprintf(
    "Enrolled: %d participants\n%d valid measurements",
    nrow(baseline),
    nrow(included)
  ),
  cross_sectional = sprintf(
    "Change since pre-war\n%d participants",
    nrow(baseline)
  ),
  returned = sprintf(
    "Returned for follow-up\n%d participants (%.0f%%)",
    n_followup,
    100 * n_followup / nrow(baseline)
  ),
  implausible = sprintf(
    "Excluded: %d participants\n(%d measurements)\nBMI change\n> 1 kg/m2 per day",
    length(implausible_ids),
    sum(longitudinal_all$id %in% implausible_ids)
  ),
  longitudinal = sprintf(
    "Change during follow-up\n%d participants\n%d measurements",
    n_distinct(longitudinal$id),
    nrow(longitudinal)
  )
)

# Numbers in the text ---------------------------------------------------------
numbers_participation <- tribble(
  ~location, ~quantity, ~value,
  "Abstract; Results, participation", "Study period",
  paste(format(min(included$record_date), "%e %B"), "to",
        format(max(included$record_date), "%e %B %Y")),
  "Abstract; Results, participation", "Participants; valid measurements",
  paste(nrow(baseline), nrow(included), sep = "; "),
  "Results, participation", "Records received",
  as.character(n_records_total),
  "Results, participation", "Valid measurements, % of records received",
  fmt_pct(100 * nrow(included) / n_records_total, 0),
  "Supplement, unlinked", "Median follow-up weight, kg: linked; unlinked",
  paste(followup_median_weight[["include"]],
        followup_median_weight[["invalid_no_baseline"]], sep = "; "),
  "Results, sensitivity", "Return for follow-up, OR (95% CI): Gaza City, North Gaza",
  or_ci("governorate_catGaza City, North Gaza")
)
