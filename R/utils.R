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

# gtsummary table as a page-width flextable. Without the width, flextable leaves
# Word to size the table, and it collapses inside Quarto's caption cell.
as_ft <- function(x) {
  as_flex_table(x) |>
    set_table_properties(layout = "autofit", width = 1)
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
