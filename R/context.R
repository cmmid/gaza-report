# =============================================================================
# Comparison with reference populations: change since pre-war standardised to
# adults in the Gaza Strip, recalled pre-war BMI against independent
# estimates, and published studies of adult weight change.
# Manuscript: Results "Comparison with reference populations"; Discussion
# Supplement: "Change since pre-war standardised to adults in the Gaza Strip",
#   "Pre-war BMI: comparison with independent estimates", "Published estimates
#   of adult weight change"
# Sourced after R/utils.R and R/data.R.
# =============================================================================

# Set-up ----------------------------------------------------------------------
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

# NCD-RisC modelled prevalence by BMI band and sex in 2022: Palestine by 5-year
# age group, and the world, age-standardised. Point estimates extracted from
# https://www.ncdrisc.org/data-downloads-adiposity.html
ncdrisc <- read_csv(
  here("data", "raw", "ncdrisc_2026_bmi_age_sex_2022.csv"),
  show_col_types = FALSE
) |>
  transmute(
    country,
    sex,
    age_group,
    underweight = 100 * bmi_under_18.5,
    obese = 100 * (bmi_30_35 + bmi_35_40 + bmi_40_plus)
  )

ncdrisc_age_group <- function(age) {
  lower <- pmin(5 * floor(age / 5), 85)
  case_when(
    age < 20 ~ "18-19",
    lower == 85 ~ "85plus",
    TRUE ~ paste0(lower, "-", lower + 4)
  )
}

# 2020 survey of adults aged 40 and over. The aggregated file carries means only
survey_2020 <- read_csv(
  here("data", "raw", "gaza_survey2020_kcal_bmi_agg.csv"),
  show_col_types = FALSE
) |>
  transmute(
    age_band = age_cat,
    sex = if_else(gender == "f", "Female", "Male"),
    bmi_2020 = weight / height^2
  )

# Analysis --------------------------------------------------------------------

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

## Recalled pre-war BMI against NCD-RisC estimates (tbl-prewar-reference) ----
# Recall and selection check: underweight and obesity from recalled pre-war
# weight, against Palestine weighted to participants' ages by
# sex and for both sexes at participants' sex mix
prewar_reference <- standard_set |>
  mutate(age_group = ncdrisc_age_group(age_years)) |>
  group_by(sex, age_group) |>
  summarise(
    n = n(),
    underweight_recalled = 100 * mean(bmi_prewar < 18.5),
    obese_recalled = 100 * mean(bmi_prewar >= 30),
    .groups = "drop"
  ) |>
  inner_join(
    ncdrisc |>
      filter(country == "Palestine") |>
      select(
        sex,
        age_group,
        underweight_palestine = underweight,
        obese_palestine = obese
      ),
    by = c("sex", "age_group")
  ) |>
  inner_join(
    ncdrisc |>
      filter(country == "World") |>
      select(sex, underweight_world = underweight, obese_world = obese),
    by = "sex"
  )

prewar_reference <- bind_rows(
  prewar_reference,
  mutate(prewar_reference, sex = "Both")
) |>
  group_by(sex) |>
  summarise(
    across(
      c(starts_with("underweight_"), starts_with("obese_")),
      \(x) weighted.mean(x, n)
    ),
    n = sum(n)
  ) |>
  relocate(n, .after = sex)

## Recalled pre-war BMI against the 2020 survey (tbl-external) ----
external_comparison <- baseline |>
  filter(!is.na(age_years), age_years >= 40, !is.na(bmi_prewar)) |>
  mutate(
    age_band = cut(
      age_years,
      breaks = c(40, 50, 60, 70, 120),
      right = FALSE,
      labels = c("[40,50)", "[50,60)", "[60,70)", "[70,120]")
    )
  ) |>
  group_by(age_band, sex) |>
  summarise(
    n_this_study = n(),
    mean_bmi_prewar = mean(bmi_prewar),
    sd_bmi_prewar = sd(bmi_prewar),
    .groups = "drop"
  ) |>
  mutate(age_band = as.character(age_band), sex = as.character(sex)) |>
  left_join(survey_2020, by = c("age_band", "sex"))

## Published studies of adult weight change (tbl-literature) ----
literature_weight <- tribble(
  ~Study, ~Period, ~Population, ~n, ~`Women, %`, ~Age, ~`Pre-war weight`, ~`Current weight`, ~`Mean weight, kg`, ~`Mean BMI, kg/m2`, ~`Underweight now, %`,
  "Alnabih et al. 2024", "April 2024", "Residents of North Gaza and Gaza City, recruited in shelters and markets (convenience)", "497", "33.6", "13-83 years", "Self-reported", "Measured by study team", "84.9 to 66.2", "-", "-",
  "Faris et al. 2025", "May-July 2024", "Households in all five governorates (convenience)", "1209", "53.5", "mean 38.0 years", "Self-reported", "Self-reported", "74.8 to 64.8", "26.4 to 22.8", "15.6"
)

this_study_weight <- baseline |>
  summarise(
    n = as.character(n()),
    women = sprintf("%.1f", 100 * mean(sex == "Female")),
    age = sprintf("mean %.1f years", mean(age_years, na.rm = TRUE)),
    weight = sprintf("%.1f to %.1f", mean(weight_prewar), mean(weight_entry)),
    loss = 100 * (1 - mean(weight_entry) / mean(weight_prewar)),
    bmi = sprintf("%.1f to %.1f", mean(bmi_prewar), mean(bmi_entry)),
    underweight = sprintf("%.1f", 100 * mean(bmi_entry < 18.5))
  )

literature_comparison <- literature_weight |>
  mutate(`Loss, %` = c(
    100 * (1 - 66.22 / 84.94),
    100 * (1 - 64.8 / 74.8)
  )) |>
  bind_rows(tibble(
    Study = "This study",
    Period = sprintf(
      "%s to %s",
      format(min(baseline$record_date), "%e %B"),
      format(max(baseline$record_date), "%e %B %Y")
    ),
    Population = "Staff of UNRWA and SCI (self-selected)",
    n = this_study_weight$n,
    `Women, %` = this_study_weight$women,
    Age = this_study_weight$age,
    `Pre-war weight` = "Self-reported",
    `Current weight` = "Self-measured on calibrated scales",
    `Mean weight, kg` = this_study_weight$weight,
    `Loss, %` = this_study_weight$loss,
    `Mean BMI, kg/m2` = this_study_weight$bmi,
    `Underweight now, %` = this_study_weight$underweight
  )) |>
  mutate(`Loss, %` = sprintf("%.1f", `Loss, %`)) |>
  relocate(`Loss, %`, .after = `Mean weight, kg`)

# Supplementary analysis ------------------------------------------------------

## Mean, median and geometric mean (tbl-centre-comparison) ----
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

# Recalled pre-war BMI minus the 2020 survey mean, range across age bands with
# 10 or more participants (ages 40-59), by sex
bmi_gap <- external_comparison |>
  filter(n_this_study >= 10) |>
  mutate(gap = abs(mean_bmi_prewar - bmi_2020)) |>
  group_by(sex) |>
  summarise(range = sprintf("%.1f-%.1f", min(gap), max(gap))) |>
  tibble::deframe()

# One percentage from the NCD-RisC comparison, by column and sex
reference_pct <- function(column, sex = "Both", digits = 0) {
  fmt_pct(prewar_reference[[column]][prewar_reference$sex == sex], digits)
}

numbers_context <- tribble(
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
  ),
  "Supplement, 2020 survey", "Pre-war BMI gap, ages 40-59: women; men",
  paste(bmi_gap[["Female"]], bmi_gap[["Male"]], sep = "; "),
  "Supplement, NCD-RisC", "Underweight, women: recalled; Palestine",
  paste(reference_pct("underweight_recalled", "Female", 1),
        reference_pct("underweight_palestine", "Female", 1), sep = "; "),
  "Supplement, NCD-RisC", "Obese, women: recalled; Palestine",
  paste(reference_pct("obese_recalled", "Female"),
        reference_pct("obese_palestine", "Female"), sep = "; "),
  "Supplement, NCD-RisC", "Underweight, men: recalled; Palestine",
  paste(reference_pct("underweight_recalled", "Male"),
        reference_pct("underweight_palestine", "Male"), sep = "; "),
  "Supplement, NCD-RisC", "Obese, men: recalled; Palestine",
  paste(reference_pct("obese_recalled", "Male"),
        reference_pct("obese_palestine", "Male"), sep = "; ")
)
