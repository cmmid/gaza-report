# =============================================================================
# Packages, display defaults and helpers shared by two or more topic files.
# Sourced first, before R/data.R.
# =============================================================================

pacman::p_load(
  here,
  readr,
  dplyr,
  tidyr,
  purrr,
  stringr,
  forcats,
  lubridate,
  broom.helpers,
  gtsummary,
  cardx,
  flextable,
  patchwork,
  ggplot2,
  ggpattern
)

# Display defaults ------------------------------------------------------------
theme_set(theme_bw() + theme(legend.position = "bottom"))
set_flextable_defaults(font.size = 9, padding = 3)
theme_gtsummary_compact()
set_gtsummary_theme(list("pkgwide-str:ci.sep" = " to "))

# Tables and text -------------------------------------------------------------
ft <- function(x) {
  flextable(x) |>
    set_table_properties(layout = "autofit", width = 1) |>
    theme_booktabs()
}

fmt_ci <- function(estimate, low, high, digits = 1) {
  sprintf(
    paste0("%.", digits, "f (%.", digits, "f to %.", digits, "f)"),
    estimate,
    low,
    high
  )
}

fmt_pct <- function(x, digits = 1) sprintf(paste0("%.", digits, "f%%"), x)

# CIs from add_ci() print as "low to high"
ci_statistic <- list(
  all_continuous() ~ "{conf.low} to {conf.high}",
  all_categorical() ~ "{conf.low} to {conf.high}"
)

# Log-scale estimates -----------------------------------------------------------
# Coefficients are on the log scale; 100 * (exp(b) - 1) is the percentage
# difference in weight relative to the reference level.
as_pct_difference <- function(x) 100 * (exp(x) - 1)

# Regression tables report coefficients as percentage differences
tidy_pct <- function(x, ...) {
  tidy_with_broom_or_parameters(x, ...) |>
    mutate(across(
      any_of(c("estimate", "conf.low", "conf.high")),
      as_pct_difference
    ))
}

# Mean, median and geometric mean (tbl-centre-comparison) ---------------------
# Mean, median and geometric mean of a change, each with a 95% CI.
# Mean: t-based, as in tbl_change. Median: exact order-statistic interval.
# Geometric mean: t-based on the log ratio of weight to pre-war weight,
# back-transformed to a percentage; only when `log_ratio` is given.
centre_summary <- function(x, log_ratio = NULL) {
  x <- sort(x[!is.na(x)])
  n <- length(x)
  k <- qbinom(0.025, n, 0.5)
  mean_test <- t.test(x)
  centres <- tibble(
    statistic = c("mean", "median"),
    estimate = c(unname(mean_test$estimate), median(x)),
    low = c(mean_test$conf.int[1], x[k]),
    high = c(mean_test$conf.int[2], x[n - k + 1])
  )
  if (is.null(log_ratio)) {
    return(centres)
  }
  log_test <- t.test(log_ratio)
  add_row(
    centres,
    statistic = "geometric_mean",
    estimate = as_pct_difference(unname(log_test$estimate)),
    low = as_pct_difference(log_test$conf.int[1]),
    high = as_pct_difference(log_test$conf.int[2])
  )
}

# Weight change relative to pre-war is a ratio: the geometric mean and the
# median sit on the same scale as the log-ratio models, the arithmetic mean of
# % change does not.
weight_centres <- function(data) {
  centre_summary(data$pct_weight_change, data$log_weight_ratio)
}

weight_label <- "Weight change, % of pre-war"

# Rows of centres (location, quantity, group, n, centres, optional digits) to
# one row per quantity with a "estimate (low to high)" column per statistic
format_centres <- function(rows) {
  rows |>
    mutate(digits = coalesce(digits, 1)) |>
    unnest(centres) |>
    mutate(text = fmt_ci(estimate, low, high, digits)) |>
    select(location, quantity, group, n, statistic, text) |>
    pivot_wider(names_from = statistic, values_from = text, values_fill = "n/a")
}

# Figures ---------------------------------------------------------------------
# BMI category at enrolment: viridis fill, as in fig-bmi-pyramid, and a
# triangle for underweight so the category is not shown by colour alone
# (fig-outcomes, follow-up trajectories)
bmi_colours <- function(levels = bmi_levels) {
  setNames(viridisLite::viridis(length(levels), direction = -1), levels)
}
bmi_shapes <- function(levels = bmi_levels) {
  setNames(c(24, rep(21, length(levels) - 1)), levels)
}
scale_bmi_category <- function(name = "BMI at enrolment") {
  list(
    scale_fill_manual(values = bmi_colours(), name = name, drop = FALSE),
    scale_shape_manual(values = bmi_shapes(), name = name, drop = FALSE)
  )
}

# Inset for fig-outcomes A: participants by BMI category pre-war and at
# enrolment, each tile filled by its enrolment category
bmi_category_legend <- function(data, levels = bmi_levels) {
  short <- setNames(c("Under", "Normal", "Over", "Obese"), levels)
  expand_grid(prewar = levels, entry = levels) |>
    left_join(
      count(data, prewar = bmi_category_prewar, entry = bmi_category_entry),
      by = c("prewar", "entry")
    ) |>
    mutate(
      fill = if_else(is.na(n), "white", bmi_colours(levels)[entry]),
      text_colour = if_else(entry %in% levels[3:4], "white", "grey10"),
      prewar = factor(short[prewar], levels = short),
      entry = factor(short[entry], levels = short)
    ) |>
    ggplot(aes(x = prewar, y = entry)) +
    geom_tile(aes(fill = fill), colour = "grey85") +
    geom_text(aes(label = n, colour = text_colour), size = 2.5, na.rm = TRUE) +
    scale_fill_identity() +
    scale_colour_identity() +
    coord_equal() +
    labs(x = "Pre-war BMI", y = "Enrolment BMI") +
    theme_minimal(base_size = 7) +
    theme(
      panel.grid = element_blank(),
      axis.text.x = element_text(angle = 45, hjust = 1),
      plot.background = element_rect(fill = "white", colour = NA)
    )
}

save_fig <- function(plot, name, width = 8, height = 5) {
  dir.create(here("outputs", "figures"), recursive = TRUE, showWarnings = FALSE)
  for (device in c("png", "pdf")) {
    ggsave(
      here("outputs", "figures", paste0(name, ".", device)),
      plot,
      width = width,
      height = height,
      dpi = 300
    )
  }
  plot
}
