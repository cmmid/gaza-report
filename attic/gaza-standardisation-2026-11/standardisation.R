# Superseded 2026-11-11: weight change since pre-war, BMI change and underweight
# at enrolment standardised by sex and age to adults in the Gaza Strip (US Census
# Bureau IDB, projected mid-2025), with bootstrap intervals; and the observed
# and standardised mean, median and geometric mean of weight change.
# Dropped because participants are selected on employment, which no
# standardisation by age and sex can correct. Neither result was reported in
# the manuscript or supplement.
#
# Was in R/context.R. Runs after R/utils.R and R/data.R, with
# idb2025_gaza_pop_age_sex_2025.csv from this folder copied to data/raw/.
# idb-extract.R in this folder builds that file.

pacman::p_load(rsample)

# Participants with a pre-war BMI category, a measured weight at enrolment,
# and a recorded age and sex
standard_set <- baseline |>
  filter(
    !is.na(bmi_category_prewar),
    !is.na(weight_entry),
    !is.na(age),
    !is.na(sex)
  ) |>
  mutate(
    sex = as.character(sex),
    age = as.character(age),
    pct_underweight_entry = 100 * underweight_entry
  )

# Projected population of the Gaza Strip by sex and single year of age,
# mid-2025 (US Census Bureau International Database, December 2025 release).
# Projected from the 2017 census: not adjusted for deaths or displacement
# during the war. Kept to the age range of participants, on the study's age
# categories.
population_ages <- c(18, 65)
population <- read_csv(
  here("data", "raw", "idb2025_gaza_pop_age_sex_2025.csv"),
  show_col_types = FALSE
) |>
  filter(between(age_years, population_ages[1], population_ages[2])) |>
  mutate(
    age = case_when(
      age_years < 30 ~ age_levels[1],
      age_years <= 45 ~ age_levels[2],
      TRUE ~ age_levels[3]
    )
  ) |>
  count(sex, age, wt = population, name = "population") |>
  mutate(population_share = population / sum(population))

## Standardisation to adults in the Gaza Strip (tbl-standardised) ----
standard_outcomes <- c(
  "pct_weight_change",
  "bmi_change",
  "pct_underweight_entry"
)

# Mean of each outcome by sex and age category, with that category's share of
# participants and of the population
standard_cells <- function(data) {
  data |>
    group_by(sex, age) |>
    summarise(
      n = n(),
      across(all_of(standard_outcomes), mean),
      .groups = "drop"
    ) |>
    mutate(participant_share = n / sum(n)) |>
    inner_join(population, by = c("sex", "age"))
}

# Observed: mean among participants. Standardised: the means by sex and age
# category, weighted by each category's share of the population.
standardise <- function(data) {
  cells <- standard_cells(data)
  shares <- c(observed = "participant_share", standardised = "population_share")
  map(shares, \(share) {
    summarise(
      cells,
      across(all_of(standard_outcomes), \(x) weighted.mean(x, cells[[share]]))
    )
  }) |>
    bind_rows(.id = "population") |>
    pivot_longer(
      all_of(standard_outcomes),
      names_to = "outcome",
      values_to = "estimate"
    )
}

# Bootstrap participants; population shares are held fixed. Percentile 95%
# intervals. The seed is set here, before the first random draw in the
# analysis; the centres bootstrap below draws next.
set.seed(20260612)
standardised_boot <- bootstraps(standard_set, times = 2000) |>
  mutate(
    estimates = map(splits, \(split) {
      standardise(analysis(split)) |>
        transmute(term = paste(population, outcome, sep = "|"), estimate)
    })
  ) |>
  int_pctl(estimates) |>
  separate_wider_delim(term, "|", names = c("population", "outcome")) |>
  select(population, outcome, low = .lower, high = .upper)

change_standardised <- standardise(standard_set) |>
  left_join(standardised_boot, by = c("population", "outcome"))

## Mean, median and geometric mean, standardised (tbl-centre-comparison) ----
# Median of x with weights w
weighted_median <- function(x, w) {
  order_x <- order(x)
  x[order_x][which(cumsum(w[order_x]) / sum(w) >= 0.5)[1]]
}

# Observed and standardised mean, median and geometric mean of weight change.
# Each participant is weighted by their sex and age group's share of
# participants (observed) or of the population (standardised), divided by the
# group's size; the means equal those of standardise().
standardise_centres <- function(data) {
  data <- data |>
    inner_join(
      select(
        standard_cells(data),
        sex,
        age,
        n,
        participant_share,
        population_share
      ),
      by = c("sex", "age")
    )
  shares <- c(observed = "participant_share", standardised = "population_share")
  map(shares, \(share) {
    w <- data[[share]] / data$n
    tibble(
      statistic = c("mean", "median", "geometric_mean"),
      estimate = c(
        weighted.mean(data$pct_weight_change, w),
        weighted_median(data$pct_weight_change, w),
        as_pct_difference(weighted.mean(data$log_weight_ratio, w))
      )
    )
  }) |>
    bind_rows(.id = "population")
}

# Percentile 95% intervals from 2000 bootstrap resamples, as for
# tbl-standardised. Drawn straight after standardised_boot, so its intervals
# are unchanged. The mean's interval is taken from change_standardised to
# match tbl-standardised.
centres_standardised_boot <- bootstraps(standard_set, times = 2000) |>
  mutate(
    estimates = map(splits, \(split) {
      standardise_centres(analysis(split)) |>
        transmute(term = paste(population, statistic, sep = "|"), estimate)
    })
  ) |>
  int_pctl(estimates) |>
  separate_wider_delim(term, "|", names = c("population", "statistic")) |>
  select(population, statistic, low = .lower, high = .upper)

centres_standardised <- standardise_centres(standard_set) |>
  left_join(centres_standardised_boot, by = c("population", "statistic")) |>
  rows_update(
    change_standardised |>
      filter(outcome == "pct_weight_change") |>
      transmute(population, statistic = "mean", low, high),
    by = c("population", "statistic")
  )

centres_context <- centres_standardised |>
  nest(centres = -population) |>
  transmute(
    location = "Results, reference populations; Discussion",
    quantity = weight_label,
    group = if_else(
      population == "observed",
      "Participants of known age",
      "Standardised to adults in the Gaza Strip"
    ),
    n = if_else(population == "observed", nrow(standard_set), NA),
    centres
  )

# Numbers in the text ---------------------------------------------------------
# "estimate% (low to high)" for one outcome of the standardisation, among
# participants ("observed") or adults in the Gaza Strip ("standardised")
standardised_ci <- function(outcome, population = "standardised") {
  row <- change_standardised[
    change_standardised$outcome == outcome &
      change_standardised$population == population,
  ]
  sub(" (", "% (", fmt_ci(row$estimate, row$low, row$high), fixed = TRUE)
}

# % aged under 30, among participants and among adults in the Gaza Strip
under_30 <- c(
  participants = 100 * mean(standard_set$age == age_levels[1]),
  population = 100 *
    sum(population$population_share[population$age == age_levels[1]])
)

numbers_standardisation <- tribble(
  ~location, ~quantity, ~value,
  "Results, reference populations", "Aged under 30: participants; adults in the Gaza Strip",
  paste(fmt_pct(under_30[["participants"]], 0), fmt_pct(under_30[["population"]], 0),
        sep = "; "),
  "Results, reference populations", "Standardised mean weight change (95% CI)",
  standardised_ci("pct_weight_change"),
  "Results, reference populations", "Standardised underweight at enrolment (95% CI)",
  standardised_ci("pct_underweight_entry"),
  "Supplement, standardisation", "Ages of participants in the standardisation",
  paste(min(standard_set$age_years), max(standard_set$age_years), sep = "-"),
  "Supplement, standardisation", "Participants left out: no age; other reasons; n kept",
  paste(
    sum(is.na(baseline$age)),
    nrow(baseline) - nrow(standard_set) - sum(is.na(baseline$age)),
    nrow(standard_set),
    sep = "; "
  )
)
