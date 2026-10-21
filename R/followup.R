# =============================================================================
# Weight change during follow-up, August-December 2025, among participants
# with two or more measurements.
# Manuscript: Results "Weight change during follow-up", Figure 2B
# Supplement: "Weight change during follow-up"
# Sourced after R/utils.R and R/data.R.
# =============================================================================

# Set-up ----------------------------------------------------------------------
pacman::p_load(mgcv, marginaleffects)

## Figure helpers ----
# Individual weight trajectories against calendar time; points filled by BMI
# category at enrolment, as in fig-outcomes A
plot_trajectories <- function(data, subtitle) {
  data <- mutate(
    data,
    bmi_category_entry = factor(bmi_category_entry, levels = bmi_levels)
  )
  ggplot(data, aes(x = record_date, y = pct_weight_change)) +
    geom_hline(yintercept = 0, linetype = 1, colour = "grey30") +
    geom_line(aes(group = id), colour = "grey60", alpha = 0.4) +
    geom_point(
      aes(fill = bmi_category_entry, shape = bmi_category_entry,
          size = is_first),
      colour = "grey20",
      stroke = 0.2,
      alpha = 0.85
    ) +
    scale_bmi_category() +
    scale_size_manual(values = c(`FALSE` = 1.1, `TRUE` = 1.9), guide = "none") +
    geom_vline(xintercept = ceasefire_date, linetype = 2, colour = "grey70") +
    labs(
      x = "Date of measurement, 2025",
      y = "Weight relative to pre-war (%)",
      subtitle = subtitle
    )
}

# Add a fitted follow-up trajectory (line, 95% confidence band) to a plot
add_gam_fit <- function(plot, fit) {
  plot +
    geom_ribbon(
      data = fit,
      aes(x = record_date, ymin = conf.low, ymax = conf.high),
      inherit.aes = FALSE,
      alpha = 0.2,
      fill = "grey10"
    ) +
    geom_line(
      data = fit,
      aes(x = record_date, y = estimate),
      inherit.aes = FALSE,
      linewidth = 1,
      colour = "grey10"
    )
}

# Analysis --------------------------------------------------------------------

## Follow-up trajectory (fig-outcomes B) ----
# Smooth of calendar day, participant random intercept, entry day as a
# person-level term. Outcome on the log scale, back-transformed for display.
fit_followup_gam <- function(data) {
  gam(
    log_weight_ratio ~ s(calendar_day, k = 10) + entry_day + s(id, bs = "re"),
    data = droplevels(data),
    method = "REML"
  )
}

# Population-level fitted trajectory, random effect held out. datagrid() holds
# entry day at its mean in the data the model was fitted to.
predict_gam <- function(fit) {
  grid <- datagrid(
    model = fit,
    calendar_day = seq(
      min(fit$model$calendar_day),
      max(fit$model$calendar_day),
      by = 1
    )
  )
  predictions(fit, newdata = grid, exclude = "s(id)") |>
    as_tibble() |>
    transmute(
      record_date = study_start + calendar_day,
      across(c(estimate, conf.low, conf.high), as_pct_difference)
    )
}

fit_gam <- fit_followup_gam(longitudinal)
gam_fit_all <- predict_gam(fit_gam)

# Change in fitted weight from the first to the last day of follow-up, in
# percentage points of pre-war weight, with a delta-method 95% CI
first_last_grid <- datagrid(
  model = fit_gam,
  calendar_day = range(fit_gam$model$calendar_day)
)
gam_change <- hypotheses(
  fit_gam,
  hypothesis = \(x) {
    fitted <- as_pct_difference(
      predict(x, newdata = first_last_grid, exclude = "s(id)")
    )
    data.frame(term = "last - first", estimate = fitted[2] - fitted[1])
  }
)

## Participants measured either side of the ceasefire (fig-followup-spanning) ----
longitudinal_spanning <- filter(longitudinal, spans_ceasefire)
n_spanning <- n_distinct(longitudinal_spanning$id)
fit_gam_spanning <- fit_followup_gam(longitudinal_spanning)
gam_fit_spanning <- predict_gam(fit_gam_spanning)

## Change from first to last measurement (tbl-paired) ----
# Participants measured before and after the ceasefire
paired <- longitudinal_spanning |>
  group_by(id) |>
  arrange(record_date, .by_group = TRUE) |>
  summarise(
    bmi_diff = last(bmi) - first(bmi),
    pct_diff = last(pct_weight_change) - first(pct_weight_change),
    days_between = as.numeric(last(record_date) - first(record_date)),
    .groups = "drop"
  )

# Mean change with t-based 95% CI, i.e. a paired t-test of last vs first
tbl_paired <- paired |>
  select(pct_diff, bmi_diff, days_between) |>
  tbl_summary(
    label = list(
      pct_diff ~ "Weight, % of pre-war",
      bmi_diff ~ "BMI (kg/m2)",
      days_between ~ "Days between first and last measurement"
    ),
    type = everything() ~ "continuous",
    statistic = list(
      c(pct_diff, bmi_diff) ~ "{mean}",
      days_between ~ "{median}"
    ),
    digits = list(pct_diff ~ 1, bmi_diff ~ 2, days_between ~ 0)
  ) |>
  add_ci(
    include = c(pct_diff, bmi_diff),
    method = everything() ~ "t.test",
    statistic = ci_statistic,
    style_fun = list(
      pct_diff ~ label_style_number(digits = 1),
      bmi_diff ~ label_style_number(digits = 2)
    ),
    pattern = "{stat} ({ci})"
  )

# Supplementary analysis ------------------------------------------------------

## Mean, median and geometric mean (tbl-centre-comparison) ----
centres_followup <- tibble(
  location = "Results, follow-up",
  quantity = "Change from first to last measurement, percentage points of pre-war weight",
  group = "Measured before and after the ceasefire",
  n = nrow(paired),
  centres = list(centre_summary(paired$pct_diff))
)

# Numbers in the text ---------------------------------------------------------
# "estimate% (low to high)" for one row of a fitted follow-up trajectory
fit_ci <- function(fit, row) {
  paste0(
    sprintf("%.1f%%", fit$estimate[row]),
    sprintf(" (%.1f to %.1f)", fit$conf.low[row], fit$conf.high[row])
  )
}

numbers_followup <- tribble(
  ~location, ~quantity, ~value,
  "Abstract; Results, follow-up", "Fitted change over follow-up, percentage points (95% CI)",
  fmt_ci(gam_change$estimate, gam_change$conf.low, gam_change$conf.high),
  "Results, follow-up", "Effective degrees of freedom of the calendar-day smooth (1 = linear)",
  sprintf("%.2f", summary(fit_gam)$edf[1]),
  "Results, follow-up", "Fitted weight, first day of follow-up",
  paste(format(first(gam_fit_all$record_date), "%e %B"), fit_ci(gam_fit_all, 1)),
  "Results, follow-up", "Fitted weight, last day of follow-up",
  paste(format(last(gam_fit_all$record_date), "%e %B"),
        fit_ci(gam_fit_all, nrow(gam_fit_all))),
  "Results, follow-up", "Measurements; participants in the follow-up model",
  paste(nrow(longitudinal), n_distinct(longitudinal$id), sep = "; "),
  "Results, follow-up", "Participants measured before and after the ceasefire",
  as.character(n_spanning),
  "Results, follow-up", "Participants in the paired first-to-last change",
  as.character(nrow(paired)),
  "Results, follow-up", "Participants dropped for implausible BMI change; their measurements",
  paste(length(implausible_ids), sum(longitudinal_all$id %in% implausible_ids),
        sep = "; ")
)
