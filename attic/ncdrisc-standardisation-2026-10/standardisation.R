# Superseded 2026-10-13: underweight standardised to NCD-RisC reference pre-war BMI
# distributions (Palestine, world), weighted by WPP 2024 population of Palestine.
# Was R/analysis.R lines 522-719. Needs loss_set and the helpers above it in
# R/analysis.R, and wpp2024_palestine_pop_age_sex_2023.csv from this folder in data/raw/.

# -----------------------------------------------------------------------------
# Underweight standardised to reference pre-war BMI distributions
# -----------------------------------------------------------------------------

# NCD-RisC modelled prevalence by BMI band and sex in 2022: Palestine by 5-year
# age group, and the world, age-standardised. Point estimates extracted from
# https://www.ncdrisc.org/data-downloads-adiposity.html
ncdrisc <- read_csv(
  here("data", "raw", "ncdrisc_2026_bmi_age_sex_2022.csv"),
  show_col_types = FALSE
)

# Population of Palestine by sex and 5-year age group, 1 July 2023 (UN World
# Population Prospects 2024), kept to the age range of participants.
population_ages <- c(18, 64)
population <- read_csv(
  here("data", "raw", "wpp2024_palestine_pop_age_sex_2023.csv"),
  show_col_types = FALSE
) |>
  filter(age_lower <= population_ages[2])

# Reference CDF of pre-war BMI per country, sex and age group: monotone spline
# through the cumulative band prevalences on log BMI, exact at the NCD-RisC
# cut-points. Tails pinned at BMI 12 and 60.
bmi_knots <- c(12, 18.5, 20, 25, 30, 35, 40, 60)

reference_cdf <- ncdrisc |>
  rowwise() |>
  mutate(
    cdf = list(splinefun(
      log(bmi_knots),
      c(0, cumsum(c_across(starts_with("bmi_")))[1:6], 1),
      method = "hyman"
    ))
  ) |>
  ungroup() |>
  select(country, sex, age_group, cdf)

cdf_at <- function(cdf, bmi) {
  pmin(pmax(cdf(log(pmin(pmax(bmi, 12), 60))), 0), 1)
}

ncdrisc_age_group <- function(age) {
  lower <- pmin(5 * floor(age / 5), 85)
  case_when(
    age < 20 ~ "18-19",
    lower == 85 ~ "85plus",
    TRUE ~ paste0(lower, "-", lower + 4)
  )
}

# Study age category whose participants donate their losses to each 5-year
# age group of a reference population
donor_age_of <- function(age_group) {
  lower <- as.numeric(str_extract(age_group, "^\\d+"))
  case_when(
    lower < 30 ~ age_levels[1],
    lower < 45 ~ age_levels[2],
    TRUE ~ age_levels[3]
  )
}

standard_set <- loss_set |>
  filter(!is.na(age_years), !is.na(sex), !is.na(bmi_entry)) |>
  mutate(
    age_group = ncdrisc_age_group(age_years),
    sex = as.character(sex),
    age = as.character(age)
  )

# Each target is a reference population as strata: sex, the study age category
# that donates losses (NA = all ages), the reference CDF and a weight.
# - population: Palestine's pre-war BMI, weighted to its adult population
# - study: Palestine's pre-war BMI, weighted to participants' age and sex.
#   Checks the reference against recalled pre-war BMI and observed underweight.
# - world: the world's pre-war BMI by sex, age-standardised
standard_labels <- c(
  population = paste0(
    "Palestine, adults aged ",
    population_ages[1],
    "-",
    population_ages[2]
  ),
  study = "Palestine, age and sex of participants",
  world = "World"
)

standard_targets <- function(data) {
  palestine <- reference_cdf |>
    filter(country == "Palestine") |>
    mutate(donor_age = donor_age_of(age_group))
  list(
    population = palestine |>
      inner_join(population, by = c("sex", "age_group")) |>
      select(sex, donor_age, cdf, weight = population_thousands),
    study = palestine |>
      inner_join(
        count(data, sex, age_group, name = "weight"),
        by = c("sex", "age_group")
      ) |>
      select(sex, donor_age, cdf, weight),
    world = reference_cdf |>
      filter(country == "World") |>
      inner_join(
        count(population, sex, wt = population_thousands, name = "weight"),
        by = "sex"
      ) |>
      transmute(sex, donor_age = NA_character_, cdf, weight)
  )
}

# Percentage underweight at enrolment if a reference population had lost what
# participants of the same sex and age category lost, averaged over strata.
# A: each participant's observed log ratio applied unchanged, so loss does not
#    depend on pre-war BMI. Upper bound, as leaner participants lost less.
# B: loss scaled by pre-war BMI through the fitted gradient b, keeping each
#    participant's residual: log BMI at enrolment = (1 + b) log x + log ratio
#    - b log pre-war BMI. Lower bound, as recall error steepens the gradient.
underweight_under_reference <- function(strata, data, b) {
  by_stratum <- pmap(strata, \(sex, donor_age, cdf, weight) {
    donors <- data[
      data$sex == sex & (is.na(donor_age) | data$age == donor_age),
    ]
    threshold_a <- 18.5 / exp(donors$log_weight_ratio)
    threshold_b <- exp(
      (log(18.5) - donors$log_weight_ratio + b * log(donors$bmi_prewar)) /
        (1 + b)
    )
    c(
      underweight_prewar = cdf_at(cdf, 18.5),
      obese_prewar = 1 - cdf_at(cdf, 30),
      underweight_a = mean(cdf_at(cdf, threshold_a)),
      underweight_b = mean(cdf_at(cdf, threshold_b))
    )
  })
  100 * colSums(do.call(rbind, by_stratum) * strata$weight) / sum(strata$weight)
}

baseline_gradient <- function(data) {
  coef(lm(
    log_weight_ratio ~ log(bmi_prewar) + age_years + sex,
    data = data
  ))[["log(bmi_prewar)"]]
}

standardise_all <- function(data) {
  b <- baseline_gradient(data)
  standard_targets(data) |>
    map(\(strata) underweight_under_reference(strata, data, b)) |>
    bind_rows(.id = "target")
}

# Bootstrap participants; reference distributions and population weights are
# held fixed. Percentile 95% intervals.
standardised_boot <- bootstraps(standard_set, times = 2000) |>
  mutate(
    estimates = map(splits, \(split) {
      standardise_all(analysis(split)) |>
        pivot_longer(
          c(underweight_a, underweight_b),
          names_to = "measure",
          values_to = "estimate"
        ) |>
        transmute(term = paste(target, measure, sep = "|"), estimate)
    })
  ) |>
  int_pctl(estimates) |>
  separate_wider_delim(term, "|", names = c("target", "measure")) |>
  select(target, measure, low = .lower, high = .upper) |>
  pivot_wider(
    names_from = measure,
    values_from = c(low, high),
    names_glue = "{measure}_{.value}"
  )

underweight_standardised <- standardise_all(standard_set) |>
  left_join(standardised_boot, by = "target") |>
  mutate(reference = standard_labels[target], .after = target)

# Recall and selection check: obesity from recalled pre-war weight vs NCD-RisC
# Palestine, standardised to this study's age mix within each sex
palestine_obese_by_sex <- standard_set |>
  group_by(sex) |>
  group_modify(\(d, key) {
    reference <- reference_cdf |>
      filter(country == "Palestine", sex == key$sex) |>
      inner_join(count(d, age_group), by = "age_group")
    tibble(
      n = nrow(d),
      obese_recalled = 100 * mean(d$bmi_prewar >= 30),
      obese_reference = 100 *
        weighted.mean(
          map_dbl(reference$cdf, \(cdf) 1 - cdf_at(cdf, 30)),
          reference$n
        )
    )
  }) |>
  ungroup()
