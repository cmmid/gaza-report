# =============================================================================
# Participation and surveillance system description
# Manuscript: Results "Participation", "Weight change during follow-up"
#   (return), "Performance of the surveillance system"
# Supplement: "Participation and data collection"
# Source after R/utils.R and R/data.R
# =============================================================================

# Set-up ----------------------------------------------------------------------
pacman::p_load(broom)

# Famine confirmed by IPC, 22 August 2025
famine_date <- as_date("2025-08-22")
# Recruitment advertisements
advert_dates <- as_date(c("2025-07-25", "2025-10-19"))
second_wave_start <- advert_dates[2]
# Public dashboard
dashboard_dates <- setNames(as_date(c("2025-08-02")), c("live"))

# Helper to count records and participants through each exclusion step
n_exclusion <- function(label, column = "n_records") {
  exclusions[[column]][exclusions$record_remove == label]
}

# Analysis --------------------------------------------------------------------

## Records and exclusions (tbl-exclusions) ----
n_records_total <- n_exclusion("invalid_nonconsent", "n_remaining") +
  n_exclusion("invalid_nonconsent")

## Unlinked follow-up measurements (fig-unlinked) ----
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

## Representativeness within the sample (tbl-balance-cohort, tbl-balance-followup) ----
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

## Return for follow-up (tbl-return) ----
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

## Timeliness ----
# Days from the date recorded on each form to its arrival on the server, over
# all forms received
submission_lag <- map2(
  c("gaza_adult_weight_form1.csv", "gaza_adult_weight_form2.csv"),
  c("note_identification2-date_today", "note_identification2-date_collected"),
  \(file, recorded) {
    read_csv(
      here("data", "raw", file),
      show_col_types = FALSE,
      guess_max = 5000
    ) |>
      transmute(
        recorded = as_date(.data[[recorded]]),
        lag = as.numeric(as_date(SubmissionDate) - recorded)
      )
  }
) |>
  bind_rows() |>
  filter(recorded >= study_start, lag >= 0) |>
  pull(lag)

## System timeline and data flow (fig-system) ----
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
  date = c(advert_dates, dashboard_dates, famine_date, ceasefire_date),
  label = c(
    "Advertised",
    "Re-advertised",
    "Dashboard live",
    "Famine confirmed",
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
    fmt_n(
      n_exclusion("invalid_nonconsent", "n_participants_remaining") +
        n_exclusion("invalid_nonconsent", "n_participants")
    )
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
    paste0(
      "Enrolled: %d participants, %d valid measurements\n",
      "Sex, age, governorate, role, dependent children,\n",
      "height, recalled pre-war weight, measured weight"
    ),
    nrow(baseline),
    nrow(included)
  ),
  cross_sectional = sprintf(
    "Change since pre-war\n%d participants\nRecalled pre-war and enrolment weight",
    nrow(baseline)
  ),
  returned = sprintf(
    "Returned for follow-up\n%d participants (%.0f%%)",
    n_followup,
    100 * n_followup / nrow(baseline)
  ),
  implausible = sprintf(
    "Excluded: %d participants\n(%d measurements)\nBMI change > 1 kg/m2 per day",
    length(implausible_ids),
    sum(longitudinal_all$id %in% implausible_ids)
  ),
  longitudinal = sprintf(
    "Change during follow-up\n%d participants\n%d measurements",
    n_distinct(longitudinal$id),
    nrow(longitudinal)
  )
)

# Supplementary analysis ------------------------------------------------------

## Mean, median and geometric mean (tbl-centre-comparison) ----
centres_participation <- baseline |>
  group_by(
    group = if_else(has_followup, "2+ measurements", "Single measurement")
  ) |>
  summarise(n = n(), centres = list(weight_centres(pick(everything())))) |>
  arrange(desc(group)) |>
  mutate(
    location = "Results, follow-up",
    quantity = weight_label
  )

# Numbers in the text ---------------------------------------------------------
numbers_participation <- tribble(
  ~location                                                                                                                                                                                   , ~quantity                                                     , ~value ,
  "Abstract; Results, participation"                                                                                                                                                          , "Study period"                                                ,
  paste(format(min(included$record_date), "%e %B"), "to", format(max(included$record_date), "%e %B %Y"))                                                                                      ,
  "Abstract; Results, participation"                                                                                                                                                          , "Participants; valid measurements"                            ,
  paste(nrow(baseline), nrow(included), sep = "; ")                                                                                                                                           ,
  "Results, participation"                                                                                                                                                                    , "Records received; participant IDs"                           ,
  paste(n_records_total, n_exclusion("invalid_nonconsent", "n_participants_remaining") + n_exclusion("invalid_nonconsent", "n_participants"), sep = "; ")                                     ,
  "Results, participation"                                                                                                                                                                    , "Valid measurements, % of records received"                   ,
  fmt_pct(100 * nrow(included) / n_records_total, 0)                                                                                                                                          ,
  "Results, participation"                                                                                                                                                                    , "Enrolled before famine confirmed; between; from second wave" ,
  paste(sum(baseline$date_entry < famine_date), sum(baseline$date_entry >= famine_date & baseline$date_entry < second_wave_start), sum(baseline$date_entry >= second_wave_start), sep = "; ") ,
  "Discussion; Supplement, unlinked"                                                                                                                                                          , "Median follow-up weight, kg: linked; unlinked"               ,
  paste(followup_median_weight[["include"]], followup_median_weight[["invalid_no_baseline"]], sep = "; ")                                                                                     ,
  "Results, follow-up"                                                                                                                                                                        , "Return for follow-up, OR (95% CI): Gaza City, North Gaza"    ,
  or_ci("governorate_catGaza City, North Gaza")                                                                                                                                               ,
  "Results, performance"                                                                                                                                                                      , "Forms on the server on the day recorded; within 7 days"      ,
  paste(fmt_pct(100 * mean(submission_lag == 0), 0), fmt_pct(100 * mean(submission_lag <= 7), 1), sep = "; ")
)
