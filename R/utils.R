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
# Text width of report/reference.docx: A4 less 2 cm margins, in inches
page_width <- (21 - 2 * 2) / 2.54

# Fixed column widths that fill the page. Each column keeps its natural,
# unwrapped width, and only the widest columns are narrowed, to a common cap,
# until the table fits. Left to itself, Word squeezes short columns instead.
# paginate() keeps a table on one page where it fits.
fit_page <- function(x, width = page_width) {
  w <- dim_pretty(x)$widths
  if (sum(w) > width) {
    cap <- uniroot(\(cap) sum(pmin(w, cap)) - width, c(0, max(w)))$root
    w <- pmin(w, cap)
  }
  x |>
    width(width = w * width / sum(w)) |>
    set_table_properties(layout = "fixed") |>
    paginate(init = TRUE, hdr_ftr = TRUE)
}

# Tables have no Quarto tbl- label: Quarto nests a labelled table inside a
# caption table, which breaks the docx. Each caption is instead typed, with its
# number, in a "Table Caption" paragraph above the chunk; that style in
# report/reference.docx keeps the caption on the page with its table.
ft <- function(x) {
  flextable(x) |>
    theme_booktabs() |>
    fit_page()
}

# gtsummary tables, with the same font size and row height as ft()
as_ft <- function(x) {
  as_flex_table(x) |>
    fontsize(size = 9, part = "all") |>
    padding(padding.top = 3, padding.bottom = 3, part = "all") |>
    height_all(height = 0.25) |>
    fit_page()
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
