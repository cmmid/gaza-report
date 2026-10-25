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
fit_followup_gam <- function(
    data,
    formula = log_weight_ratio ~ s(calendar_day, k = 4) + entry_day + s(id, bs = "re")) {
  gam(formula, data = droplevels(data), method = "REML")
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
# percentage points of pre-war weight, with a delta-method 95% CI. Averaged
# over participants: identical for each when the random intercept is held out,
# but needed when participant enters as a fixed effect.
fitted_change <- function(fit) {
  days <- range(fit$model$calendar_day)
  grid <- datagrid(model = fit, calendar_day = days, id = unique(fit$model$id))
  hypotheses(fit, hypothesis = \(x) {
    fitted <- as_pct_difference(predict(x, newdata = grid, exclude = "s(id)"))
    data.frame(
      term = "last - first",
      estimate = mean(fitted[grid$calendar_day == days[2]]) -
        mean(fitted[grid$calendar_day == days[1]])
    )
  })
}

gam_change <- fitted_change(fit_gam)

# Spread of participants around the population trajectory: SD of the random
# intercept (variance = scale / smoothing parameter) and of the residual, on
# the log scale
sd_participant <- sqrt(fit_gam$sig2 / fit_gam$sp[["s(id)"]])
sd_residual <- sqrt(fit_gam$sig2)

## Participants measured either side of the ceasefire (fig-followup-spanning) ----
longitudinal_spanning <- filter(longitudinal, spans_ceasefire)
n_spanning <- n_distinct(longitudinal_spanning$id)
fit_gam_spanning <- fit_followup_gam(longitudinal_spanning)
gam_fit_spanning <- predict_gam(fit_gam_spanning)

# Supplementary analysis ------------------------------------------------------

## Sensitivity of the fitted change (tbl-followup-sensitivity) ----
# The later cohort contributes few, short follow-ups: check the change does not
# rest on the enrolment-day term or on comparisons between participants
longitudinal_30d <- longitudinal |>
  filter(max(record_date) - min(record_date) >= 30, .by = id)

followup_sensitivity <- tribble(
  ~model, ~fit,
  "Main model", fit_gam,
  "No term for day of enrolment",
  fit_followup_gam(longitudinal, log_weight_ratio ~ s(calendar_day, k = 4) + s(id, bs = "re")),
  "Participant as a fixed effect (change within participants only)",
  fit_followup_gam(longitudinal, log_weight_ratio ~ s(calendar_day, k = 4) + id),
  "Participants measured before and after the ceasefire", fit_gam_spanning,
  "Participants measured over 30 days or more", fit_followup_gam(longitudinal_30d)
) |>
  mutate(
    participants = map_int(fit, \(f) n_distinct(f$model$id)),
    measurements = map_int(fit, \(f) nrow(f$model)),
    days = map_dbl(fit, \(f) diff(range(f$model$calendar_day))),
    change = map_chr(fit, \(f) with(fitted_change(f), fmt_ci(estimate, conf.low, conf.high))),
    edf = map_dbl(fit, \(f) summary(f)$edf[1])
  ) |>
  select(-fit)

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
  "Results, follow-up", "SD of participant levels; residual SD (log ratio x 100)",
  sprintf("%.1f; %.1f", 100 * sd_participant, 100 * sd_residual),
  "Results, follow-up", "Share of variance between participants",
  fmt_pct(100 * sd_participant^2 / (sd_participant^2 + sd_residual^2), 0),
  "Results, follow-up", "95% of participants' fitted weight, first day of follow-up",
  with(gam_fit_all, paste(
    fmt_pct(as_pct_difference(log1p(estimate[1] / 100) - 1.96 * sd_participant)), "to",
    fmt_pct(as_pct_difference(log1p(estimate[1] / 100) + 1.96 * sd_participant))
  )),
  "Results, follow-up", "Measurements; participants in the follow-up model",
  paste(nrow(longitudinal), n_distinct(longitudinal$id), sep = "; "),
  "Results, follow-up", "Participants measured before and after the ceasefire",
  as.character(n_spanning),
  "Results, follow-up", "Participants dropped for implausible BMI change; their measurements",
  paste(length(implausible_ids), sum(longitudinal_all$id %in% implausible_ids),
        sep = "; ")
)
