# =============================================================================
# Weight change during follow-up, August-December 2025, among participants
# with two or more measurements.
# Manuscript: Results "Weight change over the study period", Figure 2B
# Supplement: "Weight change during follow-up" (tbl-followup-sensitivity,
#   fig-followup-diagnostics)
# Sourced after R/utils.R and R/data.R.
# =============================================================================

# Set-up ----------------------------------------------------------------------
pacman::p_load(mgcv, marginaleffects)

## Figure helpers ----
# Individual weight trajectories against calendar time; points filled by BMI
# category at enrolment, as in fig-outcomes A, shaped by enrolment/follow-up
plot_trajectories <- function(data, subtitle) {
  data <- mutate(
    data,
    bmi_category_entry = factor(bmi_category_entry, levels = bmi_levels),
    visit = if_else(is_first, "Enrolment", "Follow-up")
  )
  ggplot(data, aes(x = record_date, y = pct_weight_change)) +
    geom_hline(yintercept = 0, linetype = 1, colour = "grey30") +
    geom_line(aes(group = id), colour = "grey60", alpha = 0.4) +
    geom_point(
      aes(fill = bmi_category_entry, shape = visit),
      colour = "grey20",
      stroke = 0.2,
      alpha = 0.85,
      size = 1.5
    ) +
    scale_fill_manual(
      values = bmi_colours(), name = "BMI at enrolment", drop = FALSE
    ) +
    scale_shape_manual(values = c(Enrolment = 21, `Follow-up` = 24), name = NULL) +
    geom_vline(xintercept = ceasefire_date, linetype = 2, colour = "grey70") +
    labs(
      x = "Date of measurement, 2025",
      y = "Weight change relative to 2023 (%)",
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

# Supplementary analysis ------------------------------------------------------

## Sensitivity of the fitted change (tbl-followup-sensitivity) ----
# The later cohort contributes few, short follow-ups: check the change does not
# rest on the enrolment-day term or on comparisons between participants
longitudinal_30d <- longitudinal |>
  filter(max(record_date) - min(record_date) >= 30, .by = id)

# All participants, including those measured once. Without the enrolment-day
# term the change is also compared between participants enrolled at different
# times, so adjust for characteristics that differ by cohort.
followup_all_participants <- included |>
  filter(!id %in% implausible_ids) |>
  mutate(
    id = factor(id),
    log_weight_ratio = log(weight / weight_prewar),
    calendar_day = as.numeric(record_date - study_start),
    has_followup = n_obs >= 2
  )

followup_sensitivity <- tribble(
  ~model, ~fit,
  "Main model", fit_gam,
  "No term for day of enrolment",
  fit_followup_gam(longitudinal, log_weight_ratio ~ s(calendar_day, k = 4) + s(id, bs = "re")),
  "Participant as a fixed effect (change within participants only)",
  fit_followup_gam(longitudinal, log_weight_ratio ~ s(calendar_day, k = 4) + id),
  "Participants measured before and after the ceasefire",
  fit_followup_gam(filter(longitudinal, spans_ceasefire)),
  "Participants measured over 30 days or more", fit_followup_gam(longitudinal_30d),
  "Adjusted for sex, age and residence",
  fit_followup_gam(longitudinal, log_weight_ratio ~ s(calendar_day, k = 4) + entry_day +
    sex + age + governorate_cat + s(id, bs = "re")),
  "All participants, no term for day of enrolment, adjusted for sex, age, residence and any follow-up",
  fit_followup_gam(followup_all_participants, log_weight_ratio ~ s(calendar_day, k = 4) +
    sex + age + governorate_cat + has_followup + s(id, bs = "re"))
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
numbers_followup <- tribble(
  ~location, ~quantity, ~value,
  "Abstract; Results, follow-up", "Fitted change over follow-up, percentage points (95% CI)",
  fmt_ci(gam_change$estimate, gam_change$conf.low, gam_change$conf.high),
  "Results, follow-up", "Effective degrees of freedom of the calendar-day smooth (1 = linear)",
  sprintf("%.2f", summary(fit_gam)$edf[1]),
  "Results, follow-up", "Measurements; participants in the follow-up model",
  paste(nrow(longitudinal), n_distinct(longitudinal$id), sep = "; ")
)
